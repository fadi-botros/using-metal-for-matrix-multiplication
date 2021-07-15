//
//  ViewController.swift
//  MatrixMultiply
//
//  Created by fadi on 13/07/2021.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let matrix1 = MutableMatrix(width: 3, height: 3)
        let matrix2 = MutableMatrix(width: 3, height: 3)
        
        matrix1[0, 0] = 1; matrix1[1, 0] = 2; matrix1[2, 0] = 3
        matrix1[0, 1] = 4; matrix1[1, 1] = 5; matrix1[2, 1] = 6
        matrix1[0, 2] = 7; matrix1[1, 2] = 8; matrix1[2, 2] = 9
        
        matrix2[0, 0] = 5; matrix2[1, 0] = 2; matrix2[2, 0] = 3
        matrix2[0, 1] = 6; matrix2[1, 1] = 5; matrix2[2, 1] = 6
        matrix2[0, 2] = 10; matrix2[1, 2] = 8; matrix2[2, 2] = 9

        let matrix1Immutable = Matrix(wrapee: matrix1)
        let matrix2Immutable = Matrix(wrapee: matrix2)
        
        guard let defaultDevice = MTLCreateSystemDefaultDevice(),
              let matrixMultiplierMetal = MatrixMultiplierMetal(device: defaultDevice) else {
            return
        }
        
        matrixMultiplierMetal.multiply(
            matrix1: matrix1Immutable,
            matrix2: matrix2Immutable,
            completionHandler: { result in
                for x in 0..<result.width {
                    for y in 0..<result.height {
                        print(result[x, y])
                    }
                    print("---")
                }
                MatrixMultipliesMaths().multiply(
                    matrix1: matrix1Immutable,
                    matrix2: matrix2Immutable,
                    completionHandler: { result in
                        for x in 0..<result.width {
                            for y in 0..<result.height {
                                print(result[x, y])
                            }
                            print("---")
                        }
                    })
            })
        
        
        let matrix3 = MutableMatrix(width: 300, height: 300)
        let matrix4 = MutableMatrix(width: 300, height: 300)

        let matrix3Immutable = Matrix(wrapee: matrix3)
        let matrix4Immutable = Matrix(wrapee: matrix4)
        
        for x in 0..<300 {
            for y in 0..<300 {
                matrix3[x, y] = Float32(arc4random() % 100)
                matrix4[x, y] = Float32(arc4random() % 100)
            }
        }
        
        guard let defaultDevice = MTLCreateSystemDefaultDevice(),
              let matrixMultiplierMetal = MatrixMultiplierMetal(device: defaultDevice) else {
            return
        }
        
        matrixMultiplierMetal.multiply(
            matrix1: matrix3Immutable,
            matrix2: matrix4Immutable,
            completionHandler: { resultFirst in
                print("Finished")
                MatrixMultipliesMaths().multiply(
                    matrix1: matrix3Immutable,
                    matrix2: matrix4Immutable,
                    completionHandler: { resultSecond in
                        print("Finished")
                        if resultFirst.height != resultSecond.height &&
                            resultFirst.width != resultSecond.width {
                            print("NOT EQUAL")
                            return
                        }
                        for x in 0..<300 {
                            for y in 0..<300 {
                                if resultFirst[x, y] != resultSecond[x, y] {
                                    print("NOT EQUAL")
                                }
                            }
                        }
                        print("Equal")
                    })
            })
    }



}

