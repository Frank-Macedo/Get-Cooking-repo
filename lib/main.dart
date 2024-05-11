import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

// Access your API key as an environment variable (see "Set up your API key" above)

void main() => runApp(MyApp());
String? _respostaInterpretacao;

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Get Cooking',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Get Cooking'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  // ignore: library_private_types_in_public_api
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? _image;
  String texto = "";
  final picker = ImagePicker();

  Future<void> pickImageFromSource(ImageSource source) async {
    final pickedFile =
        await picker.pickImage(source: source, maxWidth: 300, maxHeight: 290);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('Nenhuma imagem selecionada.');
      }
    });
  }

  Future<void> getImage() async {
    limparDados();
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Selecionar imagem'),
          content: Text('Escolha de onde deseja selecionar a imagem:'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                pickImageFromSource(ImageSource.camera);
              },
              child: Text('Câmera'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                pickImageFromSource(ImageSource.gallery);
              },
              child: Text('Galeria'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _image == null
                ? const Text(
                    'Nenhuma imagem selecionada.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  )
                : Image.file(
                    _image!,
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: _respostaInterpretacao != null
                    ? Container(
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          _respostaInterpretacao!,
                          style: const TextStyle(fontSize: 16),
                        ),
                      )
                    : Container(
                        height: 0, // Oculta o widget se não houver resposta
                      ),
              ),
            ),
            TextField(
              // Adiciona o campo de texto para entrada do usuário
              controller: _textController,
              maxLines: null,
              decoration: const InputDecoration(
                hintText: "Quais ingredientes que você possui?",
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 60),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: enviarTextoParaInterpretacao,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.green,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                textStyle:
                    const TextStyle(fontSize: 18), // Cor do texto do botão
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ), // Adiciona a função de interpretação de texto
              child: const Text('Interpretar Texto'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _image != null ? enviarImagemParaInterpretacao : null,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                textStyle:
                    const TextStyle(fontSize: 18), // Cor do texto do botão
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Interpretar Imagem'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: getImage,
        tooltip: 'Selecionar Imagem',
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }

  Future<void> enviarImagemParaInterpretacao() async {
    if (_image != null) {
      setState(() {
        _respostaInterpretacao = "Interpretando...";
      });
      String resposta = await interpretarImagem(_image!);
      setState(() {
        _respostaInterpretacao = resposta;
      });
    }
  }

  TextEditingController _textController = TextEditingController();

  Future<void> enviarTextoParaInterpretacao() async {
    print(_textController.text);
    if (_textController.text != "") {
      setState(() {
        _respostaInterpretacao = "Interpretando...";
      });
      String resposta = await interpretarTexto(_textController.text);
      limparDados();
      setState(() {
        _respostaInterpretacao = resposta;
      });
    }
  }

  Future<String> interpretarImagem(File image) async {
    GenerativeModel model = startUpGemini("gemini-pro-vision");

    // Lendo a imagem como bytes
    final imageBytes = await image.readAsBytes();

    // Criando a parte de texto
    final prompt = TextPart(
        "Só tenho o ingrediente da imagem, e mais nada, qual receita posso fazer? ");

    // Criando a parte de imagem
    final imagePart = DataPart('image/jpeg', imageBytes);

    // Gerando o conteúdo com o modelo
    final response = await model.generateContent([
      Content.multi([prompt, imagePart])
    ]);

    // Retornando a resposta do modelo
    return response.text ??
        ''; // Adicionando um valor padrão ('') caso a resposta seja nula
  }

  GenerativeModel startUpGemini(String modelType) {
    final generationConfig = GenerationConfig(
      temperature: 1,
    );

    final safetySettings = [
      SafetySetting(HarmCategory.harassment, HarmBlockThreshold.high),
      SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.high),
    ];

    const apiKey = "AIzaSyBED6cAvK2YC3UoPiKMvI_LGXLXBFFnJAs";
    if (apiKey == "") {
      exit(1);
    }

    // Instanciando o modelo generativo
    final model = GenerativeModel(
        model: modelType,
        apiKey: apiKey,
        generationConfig: generationConfig,
        safetySettings: safetySettings);
    return model;
  }

  Future<String> interpretarTexto(String texto) async {

    final model = startUpGemini("gemini-pro");
    final content = [
      Content.text(
          "tenho somente  $texto  e mais nada, qual receita posso fazer?")
    ];
    final response = await model.generateContent(content);
    return response.text ??
        ''; // Adicionando um valor padrão ('') caso a resposta seja nula
  }

  void limparDados() {
    setState(() {
      _image = null;
      _respostaInterpretacao = null;
      _textController.clear(); // Limpar o texto do campo de texto, se houver
    });
  }
}
