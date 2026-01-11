import 'package:flutter/material.dart';

/*

TEXT FIELD

----------------------------------------------------

To use this , we need:

- text controller( to access what the user typed )
- hint text ( e.g. "Enter email" )
- obscure text ( true or false | if true hide pw **** )

*/

class MyTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final IconData icon;

  const MyTextField({
    Key? key,
    required this.controller,
    required this.hintText,
    required this.obscureText,
    required this.icon,
  }) : super(key: key);

  @override
  _MyTextFieldState createState() => _MyTextFieldState();
}

class _MyTextFieldState extends State<MyTextField>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Focus(
          onFocusChange: (hasFocus) {
            setState(() {
              _isFocused = hasFocus;
              if (hasFocus || widget.controller.text.isNotEmpty) {
                _animationController.forward();
              } else {
                _animationController.reverse();
              }
            });
          },
          child: Stack(
            children: [
              TextField(
                controller: widget.controller,
                obscureText: widget.obscureText,
                onChanged: (value) {
                  if (value.isNotEmpty && !_isFocused) {
                    _animationController.forward();
                  } else if (value.isEmpty && !_isFocused) {
                    _animationController.reverse();
                  }
                },
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    widget.icon,
                    color: _isFocused
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.7),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.tertiary,
                      width: 1.0 + _animation.value,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1.0 + _animation.value,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  fillColor: Color.lerp(
                    Theme.of(context).colorScheme.secondary,
                    Theme.of(context).colorScheme.secondary.withOpacity(0.8),
                    _animation.value,
                  ),
                  filled: true,
                ),
              ),
              Positioned(
                left: 48, // Adjust the position to account for the icon
                top: Tween<double>(
                  begin: 17,
                  end: -10,
                ).animate(_animation).value,
                child: AnimatedDefaultTextStyle(
                  duration: Duration(milliseconds: 200),
                  style: TextStyle(
                    color: _isFocused
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.7),
                    fontSize: Tween<double>(
                      begin: 16,
                      end: 12,
                    ).animate(_animation).value,
                    fontWeight: FontWeight.w400,
                  ),
                  child: Text(
                    widget.hintText,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
