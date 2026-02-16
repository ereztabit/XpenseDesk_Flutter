import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../generated/l10n/app_localizations.dart';

/// A JIRA-style tag input widget that supports email entry with validation,
/// visual feedback, animations, and keyboard navigation.
class TagInput extends StatefulWidget {
  final List<String> tags;
  final ValueChanged<List<String>> onChanged;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final bool enabled;
  final int? maxTags;
  final String? Function(String)? validator;

  const TagInput({
    super.key,
    required this.tags,
    required this.onChanged,
    this.labelText,
    this.hintText,
    this.helperText,
    this.enabled = true,
    this.maxTags,
    this.validator,
  });

  @override
  State<TagInput> createState() => _TagInputState();
}

class _TagInputState extends State<TagInput> with TickerProviderStateMixin {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  
  int? _selectedTagIndex;
  bool _showInvalidFeedback = false;
  String? _errorMessage;
  
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  
  final Map<int, AnimationController> _tagAnimationControllers = {};

  @override
  void initState() {
    super.initState();
    
    // Shake animation for invalid input
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(
        parent: _shakeController,
        curve: Curves.elasticIn,
      ),
    );
    
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _shakeController.dispose();
    for (var controller in _tagAnimationControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _handleInputComplete();
      _selectedTagIndex = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.labelText != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              widget.labelText!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        
        AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_shakeAnimation.value * ((_shakeController.value * 4).floor() % 2 == 0 ? 1 : -1), 0),
              child: child,
            );
          },
          child: Container(
            constraints: const BoxConstraints(
              minHeight: 120,
              maxHeight: 200,
            ),
            decoration: BoxDecoration(
              border: Border.all(
                color: _showInvalidFeedback 
                    ? Colors.red 
                    : Theme.of(context).colorScheme.outline,
                width: _focusNode.hasFocus ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
              color: widget.enabled 
                  ? Theme.of(context).colorScheme.surface 
                  : Theme.of(context).disabledColor.withAlpha(26),
            ),
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: KeyboardListener(
                focusNode: FocusNode(),
                onKeyEvent: _handleKeyEvent,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ...List.generate(widget.tags.length, (index) {
                      return _buildTag(
                        widget.tags[index],
                        index,
                      );
                    }),
                    
                    // Input field
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: 200,
                        maxWidth: MediaQuery.of(context).size.width,
                      ),
                      child: TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        enabled: widget.enabled && (widget.maxTags == null || widget.tags.length < widget.maxTags!),
                        style: Theme.of(context).textTheme.bodyMedium,
                        decoration: InputDecoration(
                          hintText: widget.tags.isEmpty ? widget.hintText : null,
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 6),
                        ),
                        onChanged: _onInputChanged,
                        onSubmitted: (_) => _handleInputComplete(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        
        if (widget.helperText != null || _errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 12),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                _errorMessage ?? widget.helperText!,
                key: ValueKey(_errorMessage ?? widget.helperText),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _errorMessage != null 
                      ? Colors.red 
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTag(String tag, int index) {
    final isSelected = _selectedTagIndex == index;
    
    // Get or create animation controller for this tag
    _tagAnimationControllers.putIfAbsent(
      index,
      () => AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
        value: 1.0,
      ),
    );
    
    final animController = _tagAnimationControllers[index]!;
    
    return AnimatedBuilder(
      animation: animController,
      builder: (context, child) {
        final scale = animController.value;
        final opacity = animController.value;
        
        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary.withAlpha(204)
                    : const Color(0xFFE8E3F3),
                borderRadius: BorderRadius.circular(16),
                border: isSelected
                    ? Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(13),
                    offset: const Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tag,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF5E4B8B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () => _removeTag(index),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF5E4B8B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _onInputChanged(String value) {
    // Clear any error state when user starts typing
    if (_showInvalidFeedback || _errorMessage != null) {
      setState(() {
        _showInvalidFeedback = false;
        _errorMessage = null;
      });
    }
    
    // Auto-split when multiple emails detected (paste handling)
    // Count @ symbols to detect multiple emails
    final atCount = '@'.allMatches(value).length;
    
    if (atCount > 1 || value.contains('\n') || value.contains('\r')) {
      // 1. Replace all separators with a single delimiter (|)
      String normalized = value
          .replaceAll('\n', '|')
          .replaceAll('\r', '|')
          .replaceAll(',', '|')
          .replaceAll(';', '|')
          .replaceAll(' ', '|')
          .replaceAll('\t', '|');
      
      // 2. Split by the delimiter
      final parts = normalized.split('|');
      
      // Clear the input
      _textController.clear();
      
      // 3. Collect all valid tags first
      final tagsToAdd = <String>[];
      for (var i = 0; i < parts.length; i++) {
        final trimmed = parts[i].trim().toLowerCase();
        
        if (trimmed.isEmpty) continue;
        
        // Skip duplicates
        if (widget.tags.contains(trimmed) || tagsToAdd.contains(trimmed)) {
          continue;
        }
        
        // Validate
        if (widget.validator != null) {
          final error = widget.validator!(trimmed);
          if (error != null) {
            _showInvalidInput(error);
            continue;
          }
        }
        
        // Check max tags
        if (widget.maxTags != null && (widget.tags.length + tagsToAdd.length) >= widget.maxTags!) {
          break;
        }
        
        tagsToAdd.add(trimmed);
      }
      
      // 4. Add all tags at once
      if (tagsToAdd.isNotEmpty) {
        final newTags = [...widget.tags, ...tagsToAdd];
        widget.onChanged(newTags);
        
        // Animate tags in
        for (var i = 0; i < tagsToAdd.length; i++) {
          final index = widget.tags.length + i;
          _tagAnimationControllers[index] = AnimationController(
            duration: const Duration(milliseconds: 200),
            vsync: this,
            value: 0.0,
          );
          _tagAnimationControllers[index]!.forward();
        }
        
        // Keep focus and scroll
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
          // Only request focus if input is still enabled (not at max capacity)
          final canAddMore = widget.maxTags == null || newTags.length < widget.maxTags!;
          if (mounted && !_focusNode.hasFocus && canAddMore && widget.enabled) {
            _focusNode.requestFocus();
          }
        });
      }
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    
    final key = event.logicalKey;
    
    // Handle delimiter keys: Enter, Comma, Tab, Space
    if (key == LogicalKeyboardKey.enter || 
        key == LogicalKeyboardKey.comma ||
        key == LogicalKeyboardKey.tab ||
        key == LogicalKeyboardKey.space) {
      _handleInputComplete();
      return;
    }
    
    // Handle Backspace
    if (key == LogicalKeyboardKey.backspace) {
      if (_textController.text.isEmpty && widget.tags.isNotEmpty) {
        _handleBackspace();
      }
      return;
    }
    
    // Handle Arrow keys for navigation
    if (key == LogicalKeyboardKey.arrowLeft) {
      if (_textController.text.isEmpty && widget.tags.isNotEmpty) {
        _selectPreviousTag();
      }
      return;
    }
    
    if (key == LogicalKeyboardKey.arrowRight) {
      if (_selectedTagIndex != null) {
        _selectNextTag();
      }
      return;
    }
    
    // Deselect tag when typing
    if (_selectedTagIndex != null) {
      setState(() => _selectedTagIndex = null);
    }
  }

  void _handleBackspace() {
    if (_selectedTagIndex != null) {
      // Second backspace: remove the selected tag
      _removeTag(_selectedTagIndex!);
      setState(() => _selectedTagIndex = null);
    } else {
      // First backspace: select the last tag
      setState(() {
        _selectedTagIndex = widget.tags.length - 1;
      });
    }
  }

  void _selectPreviousTag() {
    if (_selectedTagIndex == null) {
      setState(() => _selectedTagIndex = widget.tags.length - 1);
    } else if (_selectedTagIndex! > 0) {
      setState(() => _selectedTagIndex = _selectedTagIndex! - 1);
    }
  }

  void _selectNextTag() {
    if (_selectedTagIndex != null) {
      if (_selectedTagIndex! < widget.tags.length - 1) {
        setState(() => _selectedTagIndex = _selectedTagIndex! + 1);
      } else {
        setState(() => _selectedTagIndex = null);
        _focusNode.requestFocus();
      }
    }
  }

  void _handleInputComplete() {
    final input = _textController.text.trim();
    if (input.isEmpty) return;
    
    // 1. Replace all separators with a single delimiter (|)
    String normalized = input
        .replaceAll('\n', '|')
        .replaceAll('\r', '|')
        .replaceAll(',', '|')
        .replaceAll(';', '|')
        .replaceAll(' ', '|')
        .replaceAll('\t', '|');
    
    // 2. Split by the delimiter
    final parts = normalized.split('|');
    
    // Clear the input
    _textController.clear();
    
    // 3. Collect all valid tags first
    final tagsToAdd = <String>[];
    for (var part in parts) {
      final trimmed = part.trim().toLowerCase();
      
      if (trimmed.isEmpty) continue;
      
      // Skip duplicates
      if (widget.tags.contains(trimmed) || tagsToAdd.contains(trimmed)) {
        continue;
      }
      
      // Validate
      if (widget.validator != null) {
        final error = widget.validator!(trimmed);
        if (error != null) {
          _showInvalidInput(error);
          continue;
        }
      }
      
      // Check max tags
      if (widget.maxTags != null && (widget.tags.length + tagsToAdd.length) >= widget.maxTags!) {
        break;
      }
      
      tagsToAdd.add(trimmed);
    }
    
    // 4. Add all tags at once
    if (tagsToAdd.isNotEmpty) {
      final newTags = [...widget.tags, ...tagsToAdd];
      widget.onChanged(newTags);
      
      // Animate tags in
      for (var i = 0; i < tagsToAdd.length; i++) {
        final index = widget.tags.length + i;
        _tagAnimationControllers[index] = AnimationController(
          duration: const Duration(milliseconds: 200),
          vsync: this,
          value: 0.0,
        );
        _tagAnimationControllers[index]!.forward();
      }
      
      // Keep focus and scroll
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
        // Only request focus if input is still enabled (not at max capacity)
        final canAddMore = widget.maxTags == null || newTags.length < widget.maxTags!;
        if (mounted && !_focusNode.hasFocus && canAddMore && widget.enabled) {
          _focusNode.requestFocus();
        }
      });
    }
  }

  void _addTag(String tag) {
    final l10n = AppLocalizations.of(context)!;
    
    // Skip duplicates silently (server will handle)
    if (widget.tags.contains(tag)) {
      return;
    }
    
    // Validate
    if (widget.validator != null) {
      final error = widget.validator!(tag);
      if (error != null) {
        _showInvalidInput(error);
        return;
      }
    }
    
    // Check max tags
    if (widget.maxTags != null && widget.tags.length >= widget.maxTags!) {
      return;
    }
    
    // Add the tag with animation
    final newTags = [...widget.tags, tag];
    widget.onChanged(newTags);
    
    // Animate tag in
    final index = newTags.length - 1;
    _tagAnimationControllers[index] = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
      value: 0.0,
    );
    _tagAnimationControllers[index]!.forward();
    
    // Keep focus in input field for easy continuous typing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
      // Only request focus if input is still enabled (not at max capacity)
      final canAddMore = widget.maxTags == null || newTags.length < widget.maxTags!;
      if (mounted && !_focusNode.hasFocus && canAddMore && widget.enabled) {
        _focusNode.requestFocus();
      }
    });
  }

  void _removeTag(int index) {
    // Animate out
    final controller = _tagAnimationControllers[index];
    if (controller != null) {
      controller.reverse().then((_) {
        if (mounted) {
          final newTags = [...widget.tags];
          newTags.removeAt(index);
          widget.onChanged(newTags);
          
          // Clean up animation controller
          _tagAnimationControllers.remove(index);
          controller.dispose();
          
          // Rebuild tag animation controllers map with updated indices
          final updatedControllers = <int, AnimationController>{};
          _tagAnimationControllers.forEach((idx, ctrl) {
            if (idx > index) {
              updatedControllers[idx - 1] = ctrl;
            } else if (idx < index) {
              updatedControllers[idx] = ctrl;
            }
          });
          _tagAnimationControllers.clear();
          _tagAnimationControllers.addAll(updatedControllers);
        }
      });
    } else {
      // Fallback without animation
      final newTags = [...widget.tags];
      newTags.removeAt(index);
      widget.onChanged(newTags);
    }
  }

  void _showInvalidInput(String message) {
    setState(() {
      _showInvalidFeedback = true;
      _errorMessage = message;
    });
    
    // Shake animation
    _shakeController.forward(from: 0);
    
    // Auto-clear after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showInvalidFeedback = false;
          _errorMessage = null;
        });
      }
    });
  }
}
