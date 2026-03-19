import 'package:flutter/material.dart';

import 'screens/pet_home_screen.dart';
import 'theme.dart';

class DigiPetApp extends StatelessWidget {
  const DigiPetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '数码宠物机',
      theme: buildAppTheme(),
      home: const PetHomeScreen(),
    );
  }
}
