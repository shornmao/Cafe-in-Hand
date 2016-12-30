//
//  UtilityRoutines.swift
//  Cafe in Hand
//
//  Created by Shorn Mo on 2016/12/30.
//  Copyright © 2016年 Shorn Mo. All rights reserved.
//

import UIKit

func presentAlertInvalidation(_ errorMessage: String, by presenter: UIViewController) {
    let alert = UIAlertController(title: NSLocalizedString("Error", comment: "Title for Error Message Box"), message: errorMessage, preferredStyle: .alert)
    let action = UIAlertAction(title: NSLocalizedString("OK", comment: "Title of OK button"), style: .default, handler: nil)
    alert.addAction(action)
    presenter.present(alert, animated: true, completion: nil)
}

func presentAlertInformation(_ infoMessage: String, by presenter: UIViewController) {
    let alert = UIAlertController(title: NSLocalizedString("Acknowledge", comment: "Title for Info Message Box"), message: infoMessage, preferredStyle: .alert)
    let action = UIAlertAction(title: NSLocalizedString("OK", comment: "Title of OK button"), style: .default, handler: nil)
    alert.addAction(action)
    presenter.present(alert, animated: true, completion: nil)
}

func presentAlertConfirmation(_ questionMessage: String, sender: UIButton, confirmedAction: ((UIAlertAction)->Void)?, by presenter: UIViewController) {
    let alert = UIAlertController(title: NSLocalizedString("Are you sure?", comment: "Title for Confirm Message Box"), message: questionMessage, preferredStyle: .actionSheet)
    let actionYes = UIAlertAction(title: NSLocalizedString("Yes", comment: "Title of Yes button"), style: .destructive, handler: confirmedAction)
    let actionNo = UIAlertAction(title: NSLocalizedString("No", comment: "Title of No button"), style: .cancel, handler: nil)
    alert.addAction(actionYes)
    alert.addAction(actionNo)
    
    if let ppc = alert.popoverPresentationController {
        ppc.sourceView = sender
        ppc.sourceRect = sender.frame
    }
    presenter.present(alert, animated: true, completion: nil)
}
