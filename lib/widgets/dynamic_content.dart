import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/app_config_provider.dart';

/// Dynamic Text Widget
/// 
/// Loads text content from Firestore in real-time.
/// Automatically updates when the content changes in the admin panel.
/// 
/// Usage:
/// ```dart
/// DynamicText(
///   section: 'welcome',
///   key: 'title',
///   fallback: 'ברוכה הבאה',
///   style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
/// )
/// ```
class DynamicText extends StatelessWidget {
  /// The section/category in Firestore (e.g., 'welcome', 'home', 'tips')
  final String section;
  
  /// The specific text key within the section
  final String textKey;
  
  /// Fallback text if Firestore value is not available
  final String fallback;
  
  /// Optional text style
  final TextStyle? style;
  
  /// Text alignment
  final TextAlign? textAlign;
  
  /// Maximum lines
  final int? maxLines;
  
  /// Text overflow behavior
  final TextOverflow? overflow;
  
  /// Whether to show a loading shimmer while loading
  final bool showLoadingShimmer;

  const DynamicText({
    super.key,
    required this.section,
    required this.textKey,
    this.fallback = '',
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.showLoadingShimmer = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AppConfigProvider>(
      builder: (context, config, child) {
        final text = config.getText(section, textKey, fallback: fallback);
        
        if (config.isLoading && showLoadingShimmer) {
          return _buildShimmer();
        }
        
        return Text(
          text,
          style: style,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
        );
      },
    );
  }

  Widget _buildShimmer() {
    return Container(
      height: (style?.fontSize ?? 14) * 1.2,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

/// Dynamic Firestore Text Widget
/// 
/// Directly listens to a specific Firestore document field.
/// Use this when you need real-time updates from a specific document.
/// 
/// Usage:
/// ```dart
/// DynamicFirestoreText(
///   collection: 'content_management',
///   documentId: 'welcome_title',
///   field: 'content',
///   fallback: 'ברוכה הבאה',
/// )
/// ```
class DynamicFirestoreText extends StatelessWidget {
  /// Firestore collection path
  final String collection;
  
  /// Document ID
  final String documentId;
  
  /// Field name containing the text
  final String field;
  
  /// Fallback text
  final String fallback;
  
  /// Optional text style
  final TextStyle? style;
  
  /// Text alignment
  final TextAlign? textAlign;
  
  /// Maximum lines
  final int? maxLines;
  
  /// Text overflow behavior
  final TextOverflow? overflow;

  const DynamicFirestoreText({
    super.key,
    required this.collection,
    required this.documentId,
    required this.field,
    this.fallback = '',
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection(collection)
          .doc(documentId)
          .snapshots(),
      builder: (context, snapshot) {
        String text = fallback;
        
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data != null && data[field] != null) {
            text = data[field].toString();
          }
        }
        
        return Text(
          text,
          style: style,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
        );
      },
    );
  }
}

/// Dynamic Color Widget
/// 
/// Loads color from Firestore configuration and applies it to a child widget.
/// The color updates in real-time when changed in the admin panel.
/// 
/// Usage:
/// ```dart
/// DynamicColor(
///   colorKey: 'primaryColor',
///   fallback: Color(0xFFD4A1AC),
///   builder: (color) => Container(
///     color: color,
///     child: Text('Hello'),
///   ),
/// )
/// ```
class DynamicColor extends StatelessWidget {
  /// The color key from UI config (e.g., 'primaryColor', 'secondaryColor')
  final String colorKey;
  
  /// Fallback color if Firestore value is not available
  final Color fallback;
  
  /// Builder function that receives the resolved color
  final Widget Function(Color color) builder;

  const DynamicColor({
    super.key,
    required this.colorKey,
    required this.fallback,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AppConfigProvider>(
      builder: (context, config, child) {
        final color = _parseColor(config.uiConfig[colorKey], fallback);
        return builder(color);
      },
    );
  }

  Color _parseColor(dynamic value, Color fallback) {
    if (value == null) return fallback;
    
    String colorString = value.toString();
    
    // Handle hex colors
    if (colorString.startsWith('#')) {
      colorString = colorString.substring(1);
      
      // 6-digit hex
      if (colorString.length == 6) {
        final hex = int.tryParse(colorString, radix: 16);
        if (hex != null) {
          return Color(0xFF000000 + hex);
        }
      }
      
      // 8-digit hex (with alpha)
      if (colorString.length == 8) {
        final hex = int.tryParse(colorString, radix: 16);
        if (hex != null) {
          return Color(hex);
        }
      }
    }
    
    return fallback;
  }
}

/// Dynamic Color Container
/// 
/// A convenience widget that creates a container with a dynamic background color.
/// 
/// Usage:
/// ```dart
/// DynamicColorContainer(
///   colorKey: 'primaryColor',
///   child: Text('Hello'),
/// )
/// ```
class DynamicColorContainer extends StatelessWidget {
  final String colorKey;
  final Color fallback;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;
  final double? width;
  final double? height;

  const DynamicColorContainer({
    super.key,
    required this.colorKey,
    required this.fallback,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.border,
    this.boxShadow,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return DynamicColor(
      colorKey: colorKey,
      fallback: fallback,
      builder: (color) => Container(
        width: width,
        height: height,
        padding: padding,
        margin: margin,
        decoration: BoxDecoration(
          color: color,
          borderRadius: borderRadius,
          border: border,
          boxShadow: boxShadow,
        ),
        child: child,
      ),
    );
  }
}

/// Dynamic Image Widget
/// 
/// Loads an image URL from Firestore and displays it with caching.
/// Updates automatically when the image URL changes in the admin panel.
/// 
/// Usage:
/// ```dart
/// DynamicImage(
///   collection: 'content_management',
///   documentId: 'hero_image',
///   field: 'mediaUrl',
///   fallback: 'assets/images/default.png',
///   width: double.infinity,
///   height: 200,
///   fit: BoxFit.cover,
/// )
/// ```
class DynamicImage extends StatelessWidget {
  /// Firestore collection path
  final String collection;
  
  /// Document ID (optional - if null, uses field from provider config)
  final String? documentId;
  
  /// Field name containing the image URL
  final String field;
  
  /// Local asset path for fallback
  final String? fallbackAsset;
  
  /// Network URL for fallback
  final String? fallbackUrl;
  
  /// Image width
  final double? width;
  
  /// Image height
  final double? height;
  
  /// Image fit mode
  final BoxFit fit;
  
  /// Border radius
  final BorderRadius? borderRadius;
  
  /// Placeholder widget while loading
  final Widget? placeholder;
  
  /// Error widget if image fails to load
  final Widget? errorWidget;
  
  /// Duration for fade-in animation
  final Duration fadeInDuration;

  const DynamicImage({
    super.key,
    this.collection = 'admin_config',
    this.documentId,
    this.field = 'imageUrl',
    this.fallbackAsset,
    this.fallbackUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.fadeInDuration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection(collection)
          .doc(documentId ?? 'ui_config')
          .snapshots(),
      builder: (context, snapshot) {
        String? imageUrl;
        
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data != null && data[field] != null) {
            imageUrl = data[field].toString();
          }
        }
        
        // Use fallback if no URL
        if (imageUrl == null || imageUrl.isEmpty) {
          if (fallbackAsset != null) {
            return _buildAssetImage(fallbackAsset!);
          } else if (fallbackUrl != null) {
            imageUrl = fallbackUrl;
          } else {
            return _buildPlaceholder();
          }
        }
        
        return _buildNetworkImage(imageUrl!);
      },
    );
  }

  Widget _buildAssetImage(String path) {
    Widget image = Image.asset(
      path,
      width: width,
      height: height,
      fit: fit,
    );
    
    if (borderRadius != null) {
      image = ClipRRect(
        borderRadius: borderRadius!,
        child: image,
      );
    }
    
    return image;
  }

  Widget _buildNetworkImage(String url) {
    Widget image = CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      fadeInDuration: fadeInDuration,
      placeholder: (context, url) => placeholder ?? _buildPlaceholder(),
      errorWidget: (context, url, error) => errorWidget ?? _buildErrorWidget(),
    );
    
    if (borderRadius != null) {
      image = ClipRRect(
        borderRadius: borderRadius!,
        child: image,
      );
    }
    
    return image;
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade300,
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorWidget() {
    if (fallbackAsset != null) {
      return _buildAssetImage(fallbackAsset!);
    }
    
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(Icons.image_not_supported, color: Colors.grey),
      ),
    );
  }
}

/// Dynamic Hero Image
/// 
/// Special widget for hero/header images with gradient overlay support.
/// 
/// Usage:
/// ```dart
/// DynamicHeroImage(
///   imageField: 'heroImageUrl',
///   gradientColors: [Colors.transparent, Colors.black54],
///   height: 300,
/// )
/// ```
class DynamicHeroImage extends StatelessWidget {
  final String imageField;
  final String collection;
  final String? documentId;
  final double height;
  final List<Color>? gradientColors;
  final Widget? overlay;
  final String? fallbackAsset;

  const DynamicHeroImage({
    super.key,
    required this.imageField,
    this.collection = 'admin_config',
    this.documentId,
    required this.height,
    this.gradientColors,
    this.overlay,
    this.fallbackAsset,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection(collection)
          .doc(documentId ?? 'ui_config')
          .snapshots(),
      builder: (context, snapshot) {
        String? imageUrl;
        
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data != null && data[imageField] != null) {
            imageUrl = data[imageField].toString();
          }
        }
        
        return Stack(
          fit: StackFit.expand,
          children: [
            // Background image
            imageUrl != null && imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => _buildFallback(),
                    errorWidget: (context, url, error) => _buildFallback(),
                  )
                : _buildFallback(),
            
            // Gradient overlay
            if (gradientColors != null && gradientColors!.length >= 2)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: gradientColors!,
                  ),
                ),
              ),
            
            // Custom overlay
            if (overlay != null) overlay!,
          ],
        );
      },
    );
  }

  Widget _buildFallback() {
    if (fallbackAsset != null) {
      return Image.asset(
        fallbackAsset!,
        fit: BoxFit.cover,
      );
    }
    
    return Container(
      color: Colors.grey.shade300,
      child: const Center(
        child: Icon(Icons.image, size: 64, color: Colors.grey),
      ),
    );
  }
}

/// Dynamic Button
/// 
/// A button with dynamic text and colors from Firestore.
/// 
/// Usage:
/// ```dart
/// DynamicButton(
///   textSection: 'home',
///   textKey: 'cta_button',
///   fallbackText: 'התחילי עכשיו',
///   colorKey: 'primaryColor',
///   onPressed: () { ... },
/// )
/// ```
class DynamicButton extends StatelessWidget {
  final String textSection;
  final String textKey;
  final String fallbackText;
  final String colorKey;
  final Color fallbackColor;
  final VoidCallback? onPressed;
  final ButtonStyle? style;
  final bool isOutlined;
  final bool isFullWidth;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;

  const DynamicButton({
    super.key,
    required this.textSection,
    required this.textKey,
    required this.fallbackText,
    this.colorKey = 'primaryColor',
    this.fallbackColor = const Color(0xFFD4A1AC),
    this.onPressed,
    this.style,
    this.isOutlined = false,
    this.isFullWidth = false,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AppConfigProvider>(
      builder: (context, config, child) {
        final text = config.getText(textSection, textKey, fallback: fallbackText);
        final color = _parseColor(config.uiConfig[colorKey], fallbackColor);
        
        final buttonStyle = style ?? _buildButtonStyle(color);
        
        final button = isOutlined
            ? OutlinedButton(
                onPressed: onPressed,
                style: buttonStyle,
                child: Text(text),
              )
            : ElevatedButton(
                onPressed: onPressed,
                style: buttonStyle,
                child: Text(text),
              );
        
        return isFullWidth ? SizedBox(width: double.infinity, child: button) : button;
      },
    );
  }

  ButtonStyle _buildButtonStyle(Color color) {
    final baseStyle = isOutlined
        ? OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color),
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? 8),
            ),
          )
        : ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? 8),
            ),
          );
    
    return baseStyle;
  }

  Color _parseColor(dynamic value, Color fallback) {
    if (value == null) return fallback;
    
    String colorString = value.toString();
    
    if (colorString.startsWith('#')) {
      colorString = colorString.substring(1);
      
      if (colorString.length == 6) {
        final hex = int.tryParse(colorString, radix: 16);
        if (hex != null) {
          return Color(0xFF000000 + hex);
        }
      }
      
      if (colorString.length == 8) {
        final hex = int.tryParse(colorString, radix: 16);
        if (hex != null) {
          return Color(hex);
        }
      }
    }
    
    return fallback;
  }
}

/// Dynamic Card
/// 
/// A card widget that loads its content from Firestore.
/// 
/// Usage:
/// ```dart
/// DynamicCard(
///   collection: 'content_management',
///   documentId: 'featured_card',
///   titleField: 'title',
///   subtitleField: 'subtitle',
///   imageField: 'imageUrl',
/// )
/// ```
class DynamicCard extends StatelessWidget {
  final String collection;
  final String documentId;
  final String? titleField;
  final String? subtitleField;
  final String? bodyField;
  final String? imageField;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;
  final double elevation;

  const DynamicCard({
    super.key,
    required this.collection,
    required this.documentId,
    this.titleField,
    this.subtitleField,
    this.bodyField,
    this.imageField,
    this.onTap,
    this.margin,
    this.elevation = 2,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection(collection)
          .doc(documentId)
          .snapshots(),
      builder: (context, snapshot) {
        String? title;
        String? subtitle;
        String? body;
        String? imageUrl;
        
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data != null) {
            title = titleField != null ? data[titleField!]?.toString() : null;
            subtitle = subtitleField != null ? data[subtitleField!]?.toString() : null;
            body = bodyField != null ? data[bodyField!]?.toString() : null;
            imageUrl = imageField != null ? data[imageField!]?.toString() : null;
          }
        }
        
        return Card(
          margin: margin,
          elevation: elevation,
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (imageUrl != null && imageUrl.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: double.infinity,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title != null)
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                        ),
                      ],
                      if (body != null) ...[
                        const SizedBox(height: 8),
                        Text(body),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
