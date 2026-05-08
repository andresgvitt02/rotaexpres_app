

// class LoginPage extends StatefulWidget {
//   const LoginPage({super.key});

//   @override
//   State<LoginPage> createState() => _LoginPageState();
// }

// class _LoginPageState extends State<LoginPage> {
//   final emailController = TextEditingController();
//   final senhaController = TextEditingController();

//   void fazerLogin() async {
//     var response = await ApiService.login(
//       emailController.text,
//       senhaController.text,
//     );

//     if (response["user"] != null && response["user"]["tipo"] == "motoboy") {
//       Navigator.push(
//         context,
//         MaterialPageRoute(builder: (context) => const PedidosPage()),
//       );
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Acesso permitido apenas para motoboy")),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("RotaEXPRESS Login")),

//       body: Padding(
//         padding: const EdgeInsets.all(20),

//         child: Column(
//           children: [
//             TextField(
//               controller: emailController,
//               decoration: const InputDecoration(labelText: "Email"),
//             ),

//             const SizedBox(height: 20),

//             TextField(
//               controller: senhaController,
//               decoration: const InputDecoration(labelText: "Senha"),
//               obscureText: true,
//             ),

//             const SizedBox(height: 30),

//             ElevatedButton(onPressed: fazerLogin, child: const Text("Entrar")),
//           ],
//         ),
//       ),
//     );
//   }
// }
