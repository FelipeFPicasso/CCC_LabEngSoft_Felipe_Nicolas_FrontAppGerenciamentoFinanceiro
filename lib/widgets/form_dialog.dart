import 'package:flutter/material.dart';

class FormDialog extends StatelessWidget {
  final String titulo;
  final Widget formFields;
  final String? erro;
  final bool salvando;
  final VoidCallback onSalvar;
  final VoidCallback onCancelar;

  const FormDialog({
    Key? key,
    required this.titulo,
    required this.formFields,
    required this.onSalvar,
    required this.onCancelar,
    this.erro,
    this.salvando = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              titulo,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            formFields,
            if (erro != null) ...[
              const SizedBox(height: 12),
              Text(
                erro!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: salvando ? null : onCancelar,
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: salvando ? null : onSalvar,
                  child: salvando
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text('Salvar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
