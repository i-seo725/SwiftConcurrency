//
//  Network.swift
//  SwiftConcurrency
//
//  Created by 박소진 on 2023/12/19.
//

import UIKit

enum NetworkError: Error {
    case invalidResponse
    case unknown
    case invalidImage
}

/*
 GCD vs Swift Concurrency
 - completion handler의 불편함
 - 비동기를 동기처럼 사용하기
 
 <키워드>
 - Thread Explosion
 - Context Switching
 -> 코어의 수와 쓰레드의 수를 같게 만듦
 -> 같은 쓰레드 내에서 Continuation 전환 형식으로 방식 변경
 
 - async throws / try await : 비동기를 동기처럼 사용
 - Task : 비동기 함수와 동기 함수를 연결
 - async let : 몇번의 통신을 해야 할 지 개수가 명확할 때 사용 ex) dispatchGroup
 //TMDB : 드라마별로 에피소드 수가 다름, 에피소드에 대한 호출 수가 다 달라서 몇 개를 호출해야 하는지 알기 어려움
 - taskGroup : 몇 개의 통신이 들어올 지 명확하지 않을 때 + 순서가 중요하지 않을 때 사용
 */

final class Network {
    
    static let shared = Network()
    
    private init() { }
    
    //GCD로 먼저 해보기
    func fetchThumbnail(completionHandler: @escaping (UIImage) -> Void) { //지금 코드에서는 오류가 발생했을 때에 대한 처리를 못함(컴플리션이 실행이 안 됨)
        
        let url = "https://www.themoviedb.org/t/p/w600_and_h900_bestv2/9f9YsmXoy9ghqZKIVuKHkmGGZCY.jpg"
        
        DispatchQueue.global().async {
            
            if let data = try? Data(contentsOf: URL(string: url)!) { //동기 동작 코드. UI 프리징됨
                
                if let image = UIImage(data: data) {
                    
                    DispatchQueue.main.async {
                        completionHandler(image)
                    }
                    
                } //image
                
            }//data
            
        }//DispatchQueue
    }
    
    //첫번째 문제: 컴플리션 하나 빼먹었을 때 컴파일 시점에 오류가 뜨지 않음
    //두번째 문제: 둘 다 nil일 경우도 받을 수 있다. - result 타입으로 해결
    func fetchThumbnailWithURLSession(completionHandler: @escaping (Result<UIImage, NetworkError>) -> Void) {
        
        let url = URL(string: "https://www.themoviedb.org/t/p/w600_and_h900_bestv2/9f9YsmXoy9ghqZKIVuKHkmGGZCY.jpg")!
        
        //타임아웃, 캐시정책을 변경하고 싶을 때 사용한다. 타임아웃 디폴트 60초. 이후엔 실패로 간주.
        //한 번 로드가 되었다면 특정 기간내에 다시 로드할 때 디바이스에 저장된걸로 가져와짐(Network 파일 URLRequest 캐시 부분)
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 5)
        
        URLSession.shared.dataTask(with: request) { data, response, error in //URLRequest 타입과 URL 타입은 다르다.
            
            guard let data else {
                completionHandler(.failure(.unknown)) //data가 nil
                return
            }
            
            guard error == nil else {
                completionHandler(.failure(.invalidResponse))
                return
            }
            
            guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                completionHandler(.failure(.invalidResponse))
                return
            }
            
            guard let image = UIImage(data: data) else {
                completionHandler(.failure(.invalidImage))
                return
            }
            
            completionHandler(.success(image))
            
        }.resume() //URLSession
        
    }
    
    
    //async 키워드를 붙여서 비동기로 작업함을 알려줌, 에러를 던져야 해서 throws도 추가
    func fetchThumbnailAsyncAwait(value: String) async throws -> UIImage {
        
        let url = URL(string: "https://www.themoviedb.org/t/p/w600_and_h900_bestv2/\(value).jpg")!

        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 5)
        
        //tuple 형태에 맞게 표현하기, 비동기를 동기처럼 돌아가게 하려고 try await 추가
        //await : 비동기를 동기처럼 작업할 테니까 응답 올때까지 여기서 기다려라, 코드가 순서대로 실행됨
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }
        
        guard let image = UIImage(data: data) else {
            throw NetworkError.invalidImage
        }
        
        print(url.description)
        return image
    }
    
    
    func fetchThumbnailAsyncLet() async throws -> [UIImage] {
        
        async let image1 = Network.shared.fetchThumbnailAsyncAwait(value: "tV0996od52EJ6S8dLKvcVGsO7B")
        async let image2 = Network.shared.fetchThumbnailAsyncAwait(value: "oc2Zz5JS6OgukkLoBSXUPggg30i")
        async let image3 = Network.shared.fetchThumbnailAsyncAwait(value: "w7eApyAshbepBnDyYRjSeGyRHi2")

        return try await [image1, image2, image3] //try await이 return 앞에 있어서 결과가 순서대로 오지 않아도 됨
    }
    
    
    func fetchThumbnailTaskGroup() async throws -> [UIImage] {
        //배열의 수만큼 네트워크 요청
        let poster = ["tV0996od52EJ6S8dLKvcVGsO7B", "oc2Zz5JS6OgukkLoBSXUPggg30i", "w7eApyAshbepBnDyYRjSeGyRHi2"]
        
        //of: 네트워크 결과로 받고 싶은 데이터 형태
        return try await withThrowingTaskGroup(of: UIImage.self) { group in
            
            for item in poster {
                group.addTask {
                    try await self.fetchThumbnailAsyncAwait(value: item)
                }
            }
            
            var resultImages: [UIImage] = []
            
            for try await item in group {
                resultImages.append(item)
            }
            
            return resultImages
        }
    }
    
}
