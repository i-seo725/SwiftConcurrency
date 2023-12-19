//
//  ViewController.swift
//  SwiftConcurrency
//
//  Created by 박소진 on 2023/12/19.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet var posterImageView: UIImageView!
    @IBOutlet weak var posterImageView2: UIImageView!
    @IBOutlet weak var posterImageView3: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Task { //응답이 오는 순서대로 배열에 담겨서 뷰에 보여짐
            let result = try await Network.shared.fetchThumbnailTaskGroup()
            posterImageView.image = result[0]
            posterImageView2.image = result[1]
            posterImageView3.image = result[2]
        }
        
//
//        Task {
//            let result = try await Network.shared.fetchThumbnailAsyncLet()
//            posterImageView.image = result[0]
//            posterImageView2.image = result[1]
//            posterImageView3.image = result[2]
//        }
        
        //비동기로 작업할 함수인데 viewDidLoad()는 동기 함수여서 이 안에서 쓸 수 없음, 그래서 Task 안에 넣어서 비동기로 동작하게 함
//        Task {  //serial 큐로 동작하던 걸 concurrent 큐로 동작하게 만들어줌
//            let image1 = try await Network.shared.fetchThumbnailAsyncAwait(value: "tV0996od52EJ6S8dLKvcVGsO7B")
//            posterImageView.image = image1
//            
//            let image2 = try await Network.shared.fetchThumbnailAsyncAwait(value: "oc2Zz5JS6OgukkLoBSXUPggg30i")
//            posterImageView2.image = image2
//            
//            let image3 = try await Network.shared.fetchThumbnailAsyncAwait(value: "w7eApyAshbepBnDyYRjSeGyRHi2")
//            posterImageView3.image = image3
//        }
        /*
         caZSuBX9UjN3nAc1f67isPjysB7
         2vlpjEE5GxJr7CiURQ4e2DWybkw
         9269PATr0bmEXKjkpR88mzGmNYI
         */
        
//        Network.shared.fetchThumbnail { [weak self] image in
//            self?.posterImageView.image = image
//        }
        
//        Network.shared.fetchThumbnailWithURLSession { [weak self] data in
//            
//            switch data { //위 코드와 다르게 실패에 대한 대응 가능
//                
//            case .success(let success):
//                DispatchQueue.main.async {
//                    self?.posterImageView.image = success
//                }
//                
//            case .failure(let failure):
//                print(failure)
//                DispatchQueue.main.async {
//                    self?.posterImageView.backgroundColor = .gray
//                }
//            }
//            
//        }
    }


}
