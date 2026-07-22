import 'package:flutter/material.dart';
import 'package:flutter_bighustle/core/common/common/app_logo.dart';

class AuthColors {
  static const Color background = Color(0xFFF2F2F2);
  static const Color primary = Color(0xFF3F76F6);
  static const Color textDark = Color(0xFF1B1B1B);
  static const Color textMuted = Color(0xFF6C6C6C);
  static const Color fieldBorder = Color(0xFFE0E0E0);
  static const Color fieldFill = Color(0xFFFFFFFF);
  static const Color dialogSuccess = Color(0xFF3F76F6);
  static const Color dialogError = Color(0xFFE35D5D);
}

class AuthLogo extends StatelessWidget {
  final double  height;
  final double width;

  const AuthLogo({
    super.key,
      this.height=120,
     this.width = 120,
  });

  @override
  Widget build(BuildContext context) {
    return AppLogo(height: height,
    width: width,
    );
  }
}

class AuthTextField extends StatefulWidget {
  final Size size;
  final TextEditingController controller;
  final String hintText;
  final bool isPassword;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final Iterable<String>? autofillHints;
  final String? errorText;

  const AuthTextField({
    super.key,
    required this.size,
    required this.controller,
    required this.hintText,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.onChanged,
    this.autofillHints,
    this.errorText,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      obscureText: widget.isPassword ? _obscureText : false,
      validator: widget.validator,
      onChanged: widget.onChanged,
      style: TextStyle(
        fontSize: (widget.size.width * 0.045).clamp(14.0, 18.0),
        color: AuthColors.textDark,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: TextStyle(
          color: AuthColors.textMuted,
          fontSize: (widget.size.width * 0.045).clamp(14.0, 18.0),
        ),
        errorText: widget.errorText,
        filled: true,
        fillColor: AuthColors.fieldFill,
        contentPadding: EdgeInsets.symmetric(
          horizontal: widget.size.width * 0.05,
          vertical: widget.size.height * 0.02,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AuthColors.fieldBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AuthColors.fieldBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AuthColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AuthColors.dialogError),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AuthColors.dialogError,
            width: 1.5,
          ),
        ),
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                  color: AuthColors.textMuted,
                ),
                onPressed: () {
                  setState(() => _obscureText = !_obscureText);
                },
              )
            : null,
      ),
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  final Size size;
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const AuthPrimaryButton({
    super.key,
    required this.size,
    required this.label,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final buttonHeight = (size.height * 0.075).clamp(48.0, 60.0);
    return SizedBox(
      width: double.infinity,
      height: buttonHeight,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AuthColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                label,
                style: TextStyle(
                  fontSize: (size.width * 0.048).clamp(16.0, 20.0),
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

class AuthSecondaryButton extends StatelessWidget {
  final Size size;
  final String label;
  final VoidCallback? onPressed;

  const AuthSecondaryButton({
    super.key,
    required this.size,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final buttonHeight = (size.height * 0.075).clamp(48.0, 60.0);
    return SizedBox(
      width: double.infinity,
      height: buttonHeight,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AuthColors.primary,
          side: const BorderSide(color: AuthColors.fieldBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: (size.width * 0.048).clamp(16.0, 20.0),
            fontWeight: FontWeight.w600,
            color: AuthColors.primary,
          ),
        ),
      ),
    );
  }
}

class AuthOtpFields extends StatefulWidget {
  final Size size;
  final int length;
  final ValueChanged<String> onChanged;
  final bool obscureText;

  const AuthOtpFields({
    super.key,
    required this.size,
    required this.onChanged,
    this.length = 6,
    this.obscureText = true,
  });

  @override
  State<AuthOtpFields> createState() => _AuthOtpFieldsState();
}

class _AuthOtpFieldsState extends State<AuthOtpFields> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _nodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _nodes = List.generate(widget.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _notifyOtpChanged() {
    final otp = _controllers.map((c) => c.text).join();
    widget.onChanged(otp);
  }

  void _handleChanged(int index, String value) {
    if (value.length > 1) {
      final chars = value.split('');
      for (var i = 0; i < chars.length && index + i < widget.length; i++) {
        _controllers[index + i].text = chars[i];
      }
      final nextIndex =
          (index + value.length).clamp(0, widget.length - 1);
      _nodes[nextIndex].requestFocus();
      _notifyOtpChanged();
      setState(() {});
      return;
    }

    if (value.isNotEmpty && index < widget.length - 1) {
      _nodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _nodes[index - 1].requestFocus();
    }
    _notifyOtpChanged();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = (constraints.maxWidth * 0.03).clamp(6.0, 12.0);
        final totalSpacing = spacing * (widget.length - 1);
        final boxSize =
            ((constraints.maxWidth - totalSpacing) / widget.length)
                .clamp(36.0, 56.0);
        final fontSize = (boxSize * 0.45).clamp(16.0, 24.0);

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.length, (index) {
            final hasValue = _controllers[index].text.isNotEmpty;
            return Padding(
              padding: EdgeInsets.only(
                right: index == widget.length - 1 ? 0 : spacing,
              ),
              child: SizedBox(
                width: boxSize,
                height: boxSize,
                child: TextFormField(
                  controller: _controllers[index],
                  focusNode: _nodes[index],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  textInputAction: index == widget.length - 1
                      ? TextInputAction.done
                      : TextInputAction.next,
                  maxLength: 1,
                  obscureText: widget.obscureText,
                  obscuringCharacter: '*',
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    color: AuthColors.primary,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: AuthColors.fieldFill,
                    contentPadding: EdgeInsets.zero,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: hasValue
                            ? AuthColors.primary
                            : AuthColors.fieldBorder,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AuthColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                  onChanged: (value) => _handleChanged(index, value),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

Future<void> showAuthStatusDialog(
  BuildContext context, {
  required bool success,
  String? message,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (context) => _AuthStatusDialog(
      success: success,
      message: message,
    ),
  );
}

class _AuthStatusDialog extends StatelessWidget {
  final bool success;
  final String? message;

  const _AuthStatusDialog({
    required this.success,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final iconColor = success ? AuthColors.dialogSuccess : AuthColors.dialogError;
    final text =
        message ?? (success ? 'Verified successfully.' : 'Account not Verified!');
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: EdgeInsets.symmetric(horizontal: size.width * 0.12),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: size.width * 0.08,
          vertical: size.height * 0.04,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogBadge(color: iconColor, success: success),
            SizedBox(height: size.height * 0.02),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: (size.width * 0.05).clamp(16.0, 22.0),
                fontWeight: FontWeight.w600,
                color: AuthColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogBadge extends StatelessWidget {
  final Color color;
  final bool success;

  const _DialogBadge({
    required this.color,
    required this.success,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      width: 88,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _DialogDot(color: color.withOpacity(0.25), size: 12, left: 6, top: 8),
          _DialogDot(
            color: color.withOpacity(0.35),
            size: 10,
            right: 8,
            top: 16,
          ),
          _DialogDot(
            color: color.withOpacity(0.25),
            size: 8,
            left: 16,
            bottom: 10,
          ),
          _DialogDot(
            color: color.withOpacity(0.35),
            size: 12,
            right: 12,
            bottom: 6,
          ),
          Container(
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(
              success ? Icons.check : Icons.close,
              color: Colors.white,
              size: 34,
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogDot extends StatelessWidget {
  final Color color;
  final double size;
  final double? left;
  final double? right;
  final double? top;
  final double? bottom;

  const _DialogDot({
    required this.color,
    required this.size,
    this.left,
    this.right,
    this.top,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
