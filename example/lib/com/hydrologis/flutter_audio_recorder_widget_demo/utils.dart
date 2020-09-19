import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:sounds/sounds.dart';
import 'package:permission_handler/permission_handler.dart';

Future<bool> requestPermissions(BuildContext context) async {
  var granted = false;

  // Request Microphone permission if needed
  print('storage: ${await Permission.microphone.status}');
  var microphoneRequired = !await Permission.microphone.isGranted;

  /// build the 'reason' why and what we are asking permissions for.
  if (microphoneRequired) {
    var reason = "To record a message we need permission ";

    if (microphoneRequired) {
      reason += "to access your microphone";
    }

    reason += ".";

    reason += " \n\nWhen prompted click the 'Allow' button.";

    /// tell the user we are about to ask for permissions.
    if (await showAlertDialog(context, reason)) {
      var permissions = <Permission>[];
      if (microphoneRequired) permissions.add(Permission.microphone);

      /// ask for the permissions.
      await permissions.request();

      /// check the user gave us the permissions.
      granted = await Permission.microphone.isGranted;
      if (!granted) grantFailed(context);
    } else {
      granted = false;
      grantFailed(context);
    }
  } else {
    granted = true;
  }

  // we already have the required permissions.
  return granted;
}

/// Display a snackbar saying that we can't record due to lack of permissions.
void grantFailed(BuildContext context) {
  var snackBar = SnackBar(
      content: Text('Recording cannot start as you did not allow '
          'the required permissions'));

  // Find the Scaffold in the widget tree and use it to show a SnackBar.
  Scaffold.of(context).showSnackBar(snackBar);
}

Future<bool> showAlertDialog(BuildContext context, String prompt) {
  // set up the buttons
  Widget cancelButton = FlatButton(
    child: Text("Cancel"),
    onPressed: () => Navigator.of(context).pop(false),
  );
  Widget continueButton = FlatButton(
    child: Text("Continue"),
    onPressed: () => Navigator.of(context).pop(true),
  );

  // set up the AlertDialog
  var alert = AlertDialog(
    title: Text("Recording Permissions"),
    content: Text(prompt),
    actions: [
      cancelButton,
      continueButton,
    ],
  );

  // show the dialog
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return alert;
    },
  );
}
