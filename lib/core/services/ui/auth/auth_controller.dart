
// import 'dart:async';

// import 'package:flutter/cupertino.dart';
// import 'package:ttrueno_fo827e642a0c4/init_dependency.dart';
// import 'package:ttrueno_fo827e642a0c4/modules/auth/interface/auth_inerface.dart';

// import '../../../notifiers/snackbar_notifier.dart';
// import '../../app_pigeon/app_pigeon.dart';


// class AuthController extends ChangeNotifier {

//   StreamSubscription? _authStreamSubscription;

//   AuthStatus _authStatus = UnAuthenticated();
//   AuthStatus get authStatus => _authStatus;

//   AuthController(){
//     _authStreamSubscription = getAuthStream().listen(
//       (authStatus) {
//         if(authStatus != null) {
//           _authStatus = authStatus; notifyListeners();
//         }
//       }
//     );
//   }

//   @override
//   void dispose(){  
//     _authStreamSubscription?.cancel();
//     super.dispose();
//   }

//   // Future<void> logout({
//   //   required ButtonStatusNotifier? buttonStatusNotifier,
//   //   SnackbarNotifier? snackbarNotifier,
//   // }) async {
//   //   buttonStatusNotifier?.setLoading();
//   //   await serviceLocator<Logout>().call(NoParams()).then((lr) {
//   //     handleFold(
//   //       either: lr, 
//   //       buttonStatusNotifier: buttonStatusNotifier,
//   //       snackbarNotifier: snackbarNotifier
//   //     );
//   //   });
//   // }

//   Stream<AuthStatus?> getAuthStream({
//     SnackbarNotifier? snackbarNotifier,
//   }) {
//     return serviceLocator<AuthInterface>().authStream();
//   }

// }
