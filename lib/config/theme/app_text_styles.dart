import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static final heading = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static final title = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static final body = GoogleFonts.inter(
    fontSize: 14,
    color: AppColors.textPrimary,
  );

  static final caption = GoogleFonts.inter(
    fontSize: 12,
    color: AppColors.textSecondary,
  );
}