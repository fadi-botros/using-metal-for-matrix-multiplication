//
//  ViewController.swift
//  MatrixMultiply
//
//  Created by fadi on 13/07/2021.
//

import UIKit

class ViewController: UIViewController {
    
    func calculateAndCheckEquality(multiplierUsingMetal: MatrixMultiplierMetal,
                                   matrix1: MutableMatrix,
                                   matrix2: MutableMatrix) {
        let matrix1Immutable = Matrix(wrapee: matrix1)
        let matrix2Immutable = Matrix(wrapee: matrix2)
        
        let startOfGPUCalculation = Date()
        
        multiplierUsingMetal.multiply(
            matrix1: matrix1Immutable,
            matrix2: matrix2Immutable,
            completionHandler: { resultFirst in
                print("Finished GPU version in \(Date().timeIntervalSince(startOfGPUCalculation))")
                let startOfCPUCalculation = Date()
                MatrixMultipliesMaths().multiply(
                    matrix1: matrix1Immutable,
                    matrix2: matrix2Immutable,
                    completionHandler: { resultSecond in
                        print("Finished CPU version in \(Date().timeIntervalSince(startOfCPUCalculation))")
                        if resultFirst.height != resultSecond.height &&
                            resultFirst.width != resultSecond.width {
                            print("NOT EQUAL")
                            return
                        }
                        for x in 0..<resultFirst.width {
                            for y in 0..<resultFirst.height {
                                // Use epsilon comparison, so that a small margin of error is allowed so that random false "unequals" won't happen
                                if abs(resultFirst[x, y] - resultSecond[x, y]) > 0.001 {
                                    print("NOT EQUAL")
                                    return
                                }
                            }
                        }
                        print("Equal")
                    })
            })

    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        guard let defaultDevice = MTLCreateSystemDefaultDevice(),
              let matrixMultiplierMetal = MatrixMultiplierMetal(device: defaultDevice) else {
            return
        }
        
        let matrix1 = MutableMatrix(width: 3, height: 3)
        let matrix2 = MutableMatrix(width: 3, height: 3)
        
        matrix1[0, 0] = 1; matrix1[1, 0] = 2; matrix1[2, 0] = 3
        matrix1[0, 1] = 4; matrix1[1, 1] = 5; matrix1[2, 1] = 6
        matrix1[0, 2] = 7; matrix1[1, 2] = 8; matrix1[2, 2] = 9
        
        matrix2[0, 0] = 5; matrix2[1, 0] = 2; matrix2[2, 0] = 3
        matrix2[0, 1] = 6; matrix2[1, 1] = 5; matrix2[2, 1] = 6
        matrix2[0, 2] = 10; matrix2[1, 2] = 8; matrix2[2, 2] = 9

        calculateAndCheckEquality(multiplierUsingMetal: matrixMultiplierMetal,
                                  matrix1: matrix1,
                                  matrix2: matrix2)
        
        let matrix3 = MutableMatrix(width: 300, height: 300)
        let matrix4 = MutableMatrix(width: 300, height: 300)

        for x in 0..<300 {
            for y in 0..<300 {
                matrix3[x, y] = Float32(arc4random() % 100)
                matrix4[x, y] = Float32(arc4random() % 100)
            }
        }
        
        calculateAndCheckEquality(multiplierUsingMetal: matrixMultiplierMetal,
                                  matrix1: matrix3,
                                  matrix2: matrix4)
        

    }



}

