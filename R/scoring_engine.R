# ==================================================
# SWING DECISION SCORING ENGINE
# ==================================================
#
# Core philosophy:
#
# Base Decision Score
#        +
# Execution Modifier
#        =
# Final Pitch Score
#
# The decision score evaluates whether the hitter
# made the correct swing/take decision.
#
# The execution modifier evaluates what happened
# after the hitter chose to swing.
# ==================================================


# ==================================================
# ZONE GROUP
# ==================================================

score_zone_group <- function(zone) {
  
  zone <- suppressWarnings(
    as.integer(zone)
  )
  
  if (is.na(zone)) {
    return(NA_character_)
  }
  
  if (zone >= 1 && zone <= 9) {
    return("Heart")
  }
  
  if (zone >= 11 && zone <= 19) {
    return("Shadow")
  }
  
  if (zone >= 21 && zone <= 29) {
    return("Chase")
  }
  
  if (zone >= 31 && zone <= 39) {
    return("Waste")
  }
  
  NA_character_
}


# ==================================================
# COUNT STATE
# ==================================================

score_count_state <- function(
    strikes_before
) {
  
  strikes_before <- suppressWarnings(
    as.integer(strikes_before)
  )
  
  if (is.na(strikes_before)) {
    return(NA_character_)
  }
  
  if (strikes_before == 2) {
    return("2K")
  }
  
  "Pre-2K"
}


# ==================================================
# SWING / TAKE
# ==================================================

score_swing_take <- function(
    pitch_result
) {
  
  if (
    pitch_result %in% c(
      "Whiff",
      "Foul",
      "In Play"
    )
  ) {
    
    return("Swing")
    
  }
  
  if (
    pitch_result %in% c(
      "Ball",
      "Called Strike"
    )
  ) {
    
    return("Take")
    
  }
  
  NA_character_
}


# ==================================================
# BASE DECISION SCORE
# ==================================================
#
#                  PRE-2K             2K
#
# HEART
# Swing              +5               +5
# Take               -5               -7
#
# SHADOW
# Swing              -2               +1
# Take               +2               -1
#
# CHASE
# Swing              -5               -5
# Take               +5               +5
#
# WASTE
# Swing              -8               -8
# Take               +3               +3
#
# ==================================================

get_base_decision_score <- function(
    zone_group,
    count_state,
    swing_take
) {
  
  if (
    is.na(zone_group) ||
    is.na(count_state) ||
    is.na(swing_take)
  ) {
    
    return(NA_real_)
    
  }
  
  # ------------------------------------------------
  # HEART
  # ------------------------------------------------
  
  if (zone_group == "Heart") {
    
    if (
      count_state == "Pre-2K" &&
      swing_take == "Swing"
    ) {
      return(5)
    }
    
    if (
      count_state == "Pre-2K" &&
      swing_take == "Take"
    ) {
      return(-5)
    }
    
    if (
      count_state == "2K" &&
      swing_take == "Swing"
    ) {
      return(5)
    }
    
    if (
      count_state == "2K" &&
      swing_take == "Take"
    ) {
      return(-7)
    }
    
  }
  
  
  # ------------------------------------------------
  # SHADOW
  # ------------------------------------------------
  
  if (zone_group == "Shadow") {
    
    if (
      count_state == "Pre-2K" &&
      swing_take == "Swing"
    ) {
      return(-2)
    }
    
    if (
      count_state == "Pre-2K" &&
      swing_take == "Take"
    ) {
      return(2)
    }
    
    if (
      count_state == "2K" &&
      swing_take == "Swing"
    ) {
      return(1)
    }
    
    if (
      count_state == "2K" &&
      swing_take == "Take"
    ) {
      return(-1)
    }
    
  }
  
  
  # ------------------------------------------------
  # CHASE
  # ------------------------------------------------
  
  if (zone_group == "Chase") {
    
    if (
      count_state == "Pre-2K" &&
      swing_take == "Swing"
    ) {
      return(-5)
    }
    
    if (
      count_state == "Pre-2K" &&
      swing_take == "Take"
    ) {
      return(5)
    }
    
    if (
      count_state == "2K" &&
      swing_take == "Swing"
    ) {
      return(-5)
    }
    
    if (
      count_state == "2K" &&
      swing_take == "Take"
    ) {
      return(5)
    }
    
  }
  
  
  # ------------------------------------------------
  # WASTE
  # ------------------------------------------------
  
  if (zone_group == "Waste") {
    
    if (
      count_state == "Pre-2K" &&
      swing_take == "Swing"
    ) {
      return(-8)
    }
    
    if (
      count_state == "Pre-2K" &&
      swing_take == "Take"
    ) {
      return(3)
    }
    
    if (
      count_state == "2K" &&
      swing_take == "Swing"
    ) {
      return(-8)
    }
    
    if (
      count_state == "2K" &&
      swing_take == "Take"
    ) {
      return(3)
    }
    
  }
  
  NA_real_
}


# ==================================================
# BASE DECISION SCORE WITH SPECIAL RULES
# ==================================================
#
# Special rule:
#
# 2K + Shadow + Take + Strikeout Looking = -3
#
# rather than the normal -1.
# ==================================================

score_pitch_decision <- function(
    zone,
    strikes_before,
    pitch_result,
    pa_result_on_pitch = ""
) {
  
  zone_group <- score_zone_group(
    zone
  )
  
  count_state <- score_count_state(
    strikes_before
  )
  
  swing_take <- score_swing_take(
    pitch_result
  )
  
  base_score <- get_base_decision_score(
    zone_group = zone_group,
    count_state = count_state,
    swing_take = swing_take
  )
  
  # ------------------------------------------------
  # 2K SHADOW TAKE FOR STRIKE THREE
  # ------------------------------------------------
  
  if (
    identical(
      zone_group,
      "Shadow"
    ) &&
    identical(
      count_state,
      "2K"
    ) &&
    identical(
      swing_take,
      "Take"
    ) &&
    identical(
      pitch_result,
      "Called Strike"
    ) &&
    identical(
      pa_result_on_pitch,
      "Strikeout Looking"
    )
  ) {
    
    base_score <- -3
    
  }
  
  base_score
}


# ==================================================
# EXECUTION MODIFIER
# ==================================================
#
# CONTACT QUALITY
#
# Hard      +2
# Average   +1
# Weak      -1
#
#
# FOUL
#
# Heart     -1
# Shadow     0
# Chase      0
# Waste      0
#
#
# WHIFF
#
# Heart     -2
# Shadow     0
# Chase     -2
# Waste      0
#
#
# TAKE
#
# No execution modifier.
# ==================================================

get_execution_modifier <- function(
    zone_group,
    pitch_result,
    contact_quality = ""
) {
  
  if (
    is.na(zone_group) ||
    is.na(pitch_result)
  ) {
    
    return(0)
    
  }
  
  
  # ------------------------------------------------
  # IN PLAY CONTACT QUALITY
  # ------------------------------------------------
  
  if (pitch_result == "In Play") {
    
    if (contact_quality == "Hard") {
      return(2)
    }
    
    if (contact_quality == "Average") {
      return(1)
    }
    
    if (contact_quality == "Weak") {
      return(-1)
    }
    
    return(0)
    
  }
  
  
  # ------------------------------------------------
  # FOUL
  # ------------------------------------------------
  
  if (pitch_result == "Foul") {
    
    if (zone_group == "Heart") {
      return(-1)
    }
    
    return(0)
    
  }
  
  
  # ------------------------------------------------
  # WHIFF
  # ------------------------------------------------
  
  if (pitch_result == "Whiff") {
    
    if (
      zone_group %in% c(
        "Heart",
        "Chase"
      )
    ) {
      return(-2)
    }
    
    return(0)
    
  }
  
  
  # ------------------------------------------------
  # TAKES
  # ------------------------------------------------
  
  0
}


# ==================================================
# FINAL PITCH SCORE
# ==================================================

score_pitch_final <- function(
    zone,
    strikes_before,
    pitch_result,
    contact_quality = "",
    pa_result_on_pitch = ""
) {
  
  zone_group <- score_zone_group(
    zone
  )
  
  base_score <- score_pitch_decision(
    zone = zone,
    strikes_before = strikes_before,
    pitch_result = pitch_result,
    pa_result_on_pitch = pa_result_on_pitch
  )
  
  execution_modifier <- get_execution_modifier(
    zone_group = zone_group,
    pitch_result = pitch_result,
    contact_quality = contact_quality
  )
  
  if (is.na(base_score)) {
    return(NA_real_)
  }
  
  base_score + execution_modifier
}


# ==================================================
# DETAILED SCORE OUTPUT
# ==================================================

score_pitch_decision_details <- function(
    zone,
    strikes_before,
    pitch_result,
    contact_quality = "",
    pa_result_on_pitch = ""
) {
  
  zone_group <- score_zone_group(
    zone
  )
  
  count_state <- score_count_state(
    strikes_before
  )
  
  swing_take <- score_swing_take(
    pitch_result
  )
  
  base_score <- score_pitch_decision(
    zone = zone,
    strikes_before = strikes_before,
    pitch_result = pitch_result,
    pa_result_on_pitch = pa_result_on_pitch
  )
  
  execution_modifier <- get_execution_modifier(
    zone_group = zone_group,
    pitch_result = pitch_result,
    contact_quality = contact_quality
  )
  
  final_score <- score_pitch_final(
    zone = zone,
    strikes_before = strikes_before,
    pitch_result = pitch_result,
    contact_quality = contact_quality,
    pa_result_on_pitch = pa_result_on_pitch
  )
  
  data.frame(
    
    Zone = zone,
    
    Zone_Group = zone_group,
    
    Strikes_Before = strikes_before,
    
    Count_State = count_state,
    
    Pitch_Result = pitch_result,
    
    Swing_Take = swing_take,
    
    Contact_Quality = contact_quality,
    
    Base_Decision_Score = base_score,
    
    Execution_Modifier = execution_modifier,
    
    Final_Pitch_Score = final_score,
    
    stringsAsFactors = FALSE
    
  )
}

# ==================================================
# NORMALIZED PITCH GRADE
# ==================================================
#
# Converts a raw pitch score into a 0-100 grade
# based on the best and worst possible score for
# that specific count state + zone.
#
# Formula:
#
# (Pitch Score - Worst Possible)
# -------------------------------- x 100
# (Best Possible - Worst Possible)
#
# Best possible outcome = 100
# Worst possible outcome = 0
#
# ==================================================


# ==================================================
# BEST POSSIBLE SCORE
# ==================================================

get_best_possible_score <- function(
    zone_group,
    count_state
) {
  
  if (
    is.na(zone_group) ||
    is.na(count_state)
  ) {
    
    return(NA_real_)
    
  }
  
  # ------------------------------------------------
  # PRE-2K
  # ------------------------------------------------
  
  if (count_state == "Pre-2K") {
    
    if (zone_group == "Heart") {
      return(7)
    }
    
    if (zone_group == "Shadow") {
      return(2)
    }
    
    if (zone_group == "Chase") {
      return(5)
    }
    
    if (zone_group == "Waste") {
      return(3)
    }
    
  }
  
  
  # ------------------------------------------------
  # 2K
  # ------------------------------------------------
  
  if (count_state == "2K") {
    
    if (zone_group == "Heart") {
      return(7)
    }
    
    if (zone_group == "Shadow") {
      return(3)
    }
    
    if (zone_group == "Chase") {
      return(5)
    }
    
    if (zone_group == "Waste") {
      return(3)
    }
    
  }
  
  NA_real_
}


# ==================================================
# WORST POSSIBLE SCORE
# ==================================================

get_worst_possible_score <- function(
    zone_group,
    count_state
) {
  
  if (
    is.na(zone_group) ||
    is.na(count_state)
  ) {
    
    return(NA_real_)
    
  }
  
  # ------------------------------------------------
  # PRE-2K
  # ------------------------------------------------
  
  if (count_state == "Pre-2K") {
    
    if (zone_group == "Heart") {
      return(-5)
    }
    
    if (zone_group == "Shadow") {
      return(-3)
    }
    
    if (zone_group == "Chase") {
      return(-7)
    }
    
    if (zone_group == "Waste") {
      return(-9)
    }
    
  }
  
  
  # ------------------------------------------------
  # 2K
  # ------------------------------------------------
  
  if (count_state == "2K") {
    
    if (zone_group == "Heart") {
      return(-7)
    }
    
    if (zone_group == "Shadow") {
      return(-3)
    }
    
    if (zone_group == "Chase") {
      return(-7)
    }
    
    if (zone_group == "Waste") {
      return(-9)
    }
    
  }
  
  NA_real_
}


# ==================================================
# NORMALIZE RAW PITCH SCORE
# ==================================================

normalize_pitch_score <- function(
    pitch_score,
    best_possible,
    worst_possible
) {
  
  pitch_score <- suppressWarnings(
    as.numeric(pitch_score)
  )
  
  best_possible <- suppressWarnings(
    as.numeric(best_possible)
  )
  
  worst_possible <- suppressWarnings(
    as.numeric(worst_possible)
  )
  
  if (
    is.na(pitch_score) ||
    is.na(best_possible) ||
    is.na(worst_possible)
  ) {
    
    return(NA_real_)
    
  }
  
  if (
    best_possible ==
    worst_possible
  ) {
    
    return(NA_real_)
    
  }
  
  normalized_score <- (
    
    (
      pitch_score -
        worst_possible
    ) /
      
      (
        best_possible -
          worst_possible
      )
    
  ) * 100
  
  
  # ----------------------------------------------
  # SAFETY CAP
  #
  # Prevent anything below 0 or above 100
  # due to future scoring changes or bad data.
  # ----------------------------------------------
  
  normalized_score <- max(
    0,
    min(
      100,
      normalized_score
    )
  )
  
  normalized_score
}


# ==================================================
# COMPLETE PITCH GRADE
# ==================================================
#
# This is the main grading function.
#
# It calculates:
#
# Zone Group
# Count State
# Raw Pitch Score
# Best Possible
# Worst Possible
# Normalized Grade
#
# ==================================================

score_pitch_grade <- function(
    zone,
    strikes_before,
    pitch_result,
    contact_quality = "",
    pa_result_on_pitch = ""
) {
  
  zone_group <- score_zone_group(
    zone
  )
  
  count_state <- score_count_state(
    strikes_before
  )
  
  pitch_score <- score_pitch_final(
    zone = zone,
    strikes_before = strikes_before,
    pitch_result = pitch_result,
    contact_quality = contact_quality,
    pa_result_on_pitch = pa_result_on_pitch
  )
  
  best_possible <- get_best_possible_score(
    zone_group = zone_group,
    count_state = count_state
  )
  
  worst_possible <- get_worst_possible_score(
    zone_group = zone_group,
    count_state = count_state
  )
  
  normalized_grade <- normalize_pitch_score(
    pitch_score = pitch_score,
    best_possible = best_possible,
    worst_possible = worst_possible
  )
  
  normalized_grade
}


# ==================================================
# DETAILED PITCH GRADE OUTPUT
# ==================================================

score_pitch_grade_details <- function(
    zone,
    strikes_before,
    pitch_result,
    contact_quality = "",
    pa_result_on_pitch = ""
) {
  
  score_details <- score_pitch_decision_details(
    zone = zone,
    strikes_before = strikes_before,
    pitch_result = pitch_result,
    contact_quality = contact_quality,
    pa_result_on_pitch = pa_result_on_pitch
  )
  
  zone_group <-
    score_details$Zone_Group[1]
  
  count_state <-
    score_details$Count_State[1]
  
  pitch_score <-
    score_details$Final_Pitch_Score[1]
  
  best_possible <- get_best_possible_score(
    zone_group = zone_group,
    count_state = count_state
  )
  
  worst_possible <- get_worst_possible_score(
    zone_group = zone_group,
    count_state = count_state
  )
  
  normalized_grade <- normalize_pitch_score(
    pitch_score = pitch_score,
    best_possible = best_possible,
    worst_possible = worst_possible
  )
  
  data.frame(
    
    Zone =
      score_details$Zone,
    
    Zone_Group =
      score_details$Zone_Group,
    
    Strikes_Before =
      score_details$Strikes_Before,
    
    Count_State =
      score_details$Count_State,
    
    Pitch_Result =
      score_details$Pitch_Result,
    
    Swing_Take =
      score_details$Swing_Take,
    
    Contact_Quality =
      score_details$Contact_Quality,
    
    Base_Decision_Score =
      score_details$Base_Decision_Score,
    
    Execution_Modifier =
      score_details$Execution_Modifier,
    
    Pitch_Score =
      pitch_score,
    
    Best_Possible =
      best_possible,
    
    Worst_Possible =
      worst_possible,
    
    Normalized_Grade =
      normalized_grade,
    
    stringsAsFactors = FALSE
    
  )
}

# ==================================================
# PLAYER / SAMPLE GRADING
# ==================================================
#
# Takes a data frame of pitches and calculates:
#
# Overall Grade
# Pre-2K Grade
# 2K Grade
#
# It also returns pitch counts so the report always
# shows the size of the sample behind each grade.
#
# Expected columns:
#
# Zone
# Strikes_Before
# Pitch_Result
# Contact_Quality
# PA_Result_On_Pitch
#
# ==================================================


# ==================================================
# GRADE ONE DATA FRAME OF PITCHES
# ==================================================

grade_pitch_data <- function(
    pitch_data
) {
  
  if (
    is.null(pitch_data) ||
    nrow(pitch_data) == 0
  ) {
    
    return(
      data.frame()
    )
    
  }
  
  required_columns <- c(
    "Zone",
    "Strikes_Before",
    "Pitch_Result",
    "Contact_Quality",
    "PA_Result_On_Pitch"
  )
  
  missing_columns <- required_columns[
    !required_columns %in%
      names(pitch_data)
  ]
  
  if (
    length(missing_columns) > 0
  ) {
    
    stop(
      paste0(
        "Missing required columns: ",
        paste(
          missing_columns,
          collapse = ", "
        )
      )
    )
    
  }
  
  graded_rows <- lapply(
    
    seq_len(
      nrow(pitch_data)
    ),
    
    function(i) {
      
      score_pitch_grade_details(
        
        zone =
          pitch_data$Zone[i],
        
        strikes_before =
          pitch_data$Strikes_Before[i],
        
        pitch_result =
          pitch_data$Pitch_Result[i],
        
        contact_quality =
          ifelse(
            is.na(
              pitch_data$Contact_Quality[i]
            ),
            "",
            pitch_data$Contact_Quality[i]
          ),
        
        pa_result_on_pitch =
          ifelse(
            is.na(
              pitch_data$PA_Result_On_Pitch[i]
            ),
            "",
            pitch_data$PA_Result_On_Pitch[i]
          )
        
      )
      
    }
    
  )
  
  graded_data <- do.call(
    rbind,
    graded_rows
  )
  
  graded_data
}


# ==================================================
# SAFE MEAN
# ==================================================

safe_grade_mean <- function(
    x
) {
  
  x <- suppressWarnings(
    as.numeric(x)
  )
  
  x <- x[
    !is.na(x)
  ]
  
  if (
    length(x) == 0
  ) {
    
    return(NA_real_)
    
  }
  
  mean(x)
}


# ==================================================
# PLAYER GRADE SUMMARY
# ==================================================

summarize_player_grades <- function(
    pitch_data
) {
  
  graded_data <- grade_pitch_data(
    pitch_data
  )
  
  if (
    nrow(graded_data) == 0
  ) {
    
    return(
      
      data.frame(
        
        Overall_Grade = NA_real_,
        Overall_Pitches = 0,
        
        Pre2K_Grade = NA_real_,
        Pre2K_Pitches = 0,
        
        TwoK_Grade = NA_real_,
        TwoK_Pitches = 0,
        
        stringsAsFactors = FALSE
        
      )
      
    )
    
  }
  
  
  # ------------------------------------------------
  # OVERALL
  # ------------------------------------------------
  
  overall_grade <- safe_grade_mean(
    graded_data$Normalized_Grade
  )
  
  overall_pitches <- sum(
    !is.na(
      graded_data$Normalized_Grade
    )
  )
  
  
  # ------------------------------------------------
  # PRE-2K
  # ------------------------------------------------
  
  pre2k_data <- graded_data[
    graded_data$Count_State ==
      "Pre-2K",
    ,
    drop = FALSE
  ]
  
  pre2k_grade <- safe_grade_mean(
    pre2k_data$Normalized_Grade
  )
  
  pre2k_pitches <- sum(
    !is.na(
      pre2k_data$Normalized_Grade
    )
  )
  
  
  # ------------------------------------------------
  # 2K
  # ------------------------------------------------
  
  two_k_data <- graded_data[
    graded_data$Count_State ==
      "2K",
    ,
    drop = FALSE
  ]
  
  two_k_grade <- safe_grade_mean(
    two_k_data$Normalized_Grade
  )
  
  two_k_pitches <- sum(
    !is.na(
      two_k_data$Normalized_Grade
    )
  )
  
  
  # ------------------------------------------------
  # OUTPUT
  # ------------------------------------------------
  
  data.frame(
    
    Overall_Grade =
      round(
        overall_grade,
        1
      ),
    
    Overall_Pitches =
      overall_pitches,
    
    Pre2K_Grade =
      round(
        pre2k_grade,
        1
      ),
    
    Pre2K_Pitches =
      pre2k_pitches,
    
    TwoK_Grade =
      round(
        two_k_grade,
        1
      ),
    
    TwoK_Pitches =
      two_k_pitches,
    
    stringsAsFactors = FALSE
    
  )
  
}

# ==================================================
# DECISION METRICS ENGINE
# ==================================================
#
# Calculates the core hitter decision metrics used
# on the Player Report.
#
# Metrics:
#
# Heart Swing %
# Heart Take %
# Chase %
# Shadow Swing %
# Overall Swing %
# Whiff %
# Contact %
# Hard Contact %
#
# Also calculates Pre-2K and 2K splits for:
#
# Heart Swing %
# Chase %
#
# ==================================================


# ==================================================
# SAFE PERCENT
# ==================================================

safe_percent <- function(
    numerator,
    denominator
) {
  
  numerator <- suppressWarnings(
    as.numeric(numerator)
  )
  
  denominator <- suppressWarnings(
    as.numeric(denominator)
  )
  
  if (
    is.na(denominator) ||
    denominator == 0
  ) {
    
    return(NA_real_)
    
  }
  
  (
    numerator /
      denominator
  ) * 100
}


# ==================================================
# PREP DECISION METRIC DATA
# ==================================================

prepare_decision_metric_data <- function(
    pitch_data
) {
  
  if (
    is.null(pitch_data) ||
    nrow(pitch_data) == 0
  ) {
    
    return(
      data.frame()
    )
    
  }
  
  required_columns <- c(
    "Zone_Group",
    "Count_State",
    "Pitch_Result",
    "Swing_Take",
    "Contact_Quality"
  )
  
  missing_columns <- required_columns[
    !required_columns %in%
      names(pitch_data)
  ]
  
  if (
    length(missing_columns) > 0
  ) {
    
    stop(
      paste0(
        "Missing required columns: ",
        paste(
          missing_columns,
          collapse = ", "
        )
      )
    )
    
  }
  
  pitch_data
}


# ==================================================
# DECISION METRIC SUMMARY
# ==================================================

summarize_decision_metrics <- function(
    pitch_data
) {
  
  data <- prepare_decision_metric_data(
    pitch_data
  )
  
  if (
    nrow(data) == 0
  ) {
    
    return(
      data.frame(
        
        Heart_Swing_Pct = NA_real_,
        Heart_Take_Pct = NA_real_,
        
        Chase_Pct = NA_real_,
        Shadow_Swing_Pct = NA_real_,
        
        Overall_Swing_Pct = NA_real_,
        Whiff_Pct = NA_real_,
        Contact_Pct = NA_real_,
        Hard_Contact_Pct = NA_real_,
        
        Pre2K_Heart_Swing_Pct = NA_real_,
        TwoK_Heart_Swing_Pct = NA_real_,
        
        Pre2K_Chase_Pct = NA_real_,
        TwoK_Chase_Pct = NA_real_,
        
        Total_Pitches = 0,
        Total_Swings = 0,
        Total_BIP = 0,
        
        stringsAsFactors = FALSE
      )
    )
    
  }
  
  
  # ==================================================
  # BASIC FLAGS
  # ==================================================
  
  is_swing <- data$Swing_Take == "Swing"
  
  is_take <- data$Swing_Take == "Take"
  
  is_heart <- data$Zone_Group == "Heart"
  
  is_shadow <- data$Zone_Group == "Shadow"
  
  is_chase_zone <- data$Zone_Group %in%
    c(
      "Chase",
      "Waste"
    )
  
  is_pre2k <- data$Count_State == "Pre-2K"
  
  is_2k <- data$Count_State == "2K"
  
  is_whiff <- data$Pitch_Result == "Whiff"
  
  is_foul <- data$Pitch_Result == "Foul"
  
  is_in_play <- data$Pitch_Result == "In Play"
  
  is_contact <- data$Pitch_Result %in%
    c(
      "Foul",
      "In Play"
    )
  
  is_hard_contact <- (
    data$Pitch_Result == "In Play" &
      data$Contact_Quality == "Hard"
  )
  
  
  # ==================================================
  # HEART SWING %
  # ==================================================
  
  heart_pitches <- sum(
    is_heart,
    na.rm = TRUE
  )
  
  heart_swings <- sum(
    is_heart &
      is_swing,
    na.rm = TRUE
  )
  
  heart_swing_pct <- safe_percent(
    heart_swings,
    heart_pitches
  )
  
  
  # ==================================================
  # HEART TAKE %
  # ==================================================
  
  heart_takes <- sum(
    is_heart &
      is_take,
    na.rm = TRUE
  )
  
  heart_take_pct <- safe_percent(
    heart_takes,
    heart_pitches
  )
  
  
  # ==================================================
  # CHASE %
  # ==================================================
  #
  # Chase % here means:
  #
  # Swings on Chase + Waste pitches
  # --------------------------------
  # Total Chase + Waste pitches
  #
  # ==================================================
  
  chase_zone_pitches <- sum(
    is_chase_zone,
    na.rm = TRUE
  )
  
  chase_swings <- sum(
    is_chase_zone &
      is_swing,
    na.rm = TRUE
  )
  
  chase_pct <- safe_percent(
    chase_swings,
    chase_zone_pitches
  )
  
  
  # ==================================================
  # SHADOW SWING %
  # ==================================================
  
  shadow_pitches <- sum(
    is_shadow,
    na.rm = TRUE
  )
  
  shadow_swings <- sum(
    is_shadow &
      is_swing,
    na.rm = TRUE
  )
  
  shadow_swing_pct <- safe_percent(
    shadow_swings,
    shadow_pitches
  )
  
  
  # ==================================================
  # OVERALL SWING %
  # ==================================================
  
  total_pitches <- nrow(
    data
  )
  
  total_swings <- sum(
    is_swing,
    na.rm = TRUE
  )
  
  overall_swing_pct <- safe_percent(
    total_swings,
    total_pitches
  )
  
  
  # ==================================================
  # WHIFF %
  # ==================================================
  #
  # Whiffs / Swings
  #
  # ==================================================
  
  total_whiffs <- sum(
    is_whiff,
    na.rm = TRUE
  )
  
  whiff_pct <- safe_percent(
    total_whiffs,
    total_swings
  )
  
  
  # ==================================================
  # CONTACT %
  # ==================================================
  #
  # Contact / Swings
  #
  # Foul + In Play count as contact.
  #
  # ==================================================
  
  total_contact <- sum(
    is_contact,
    na.rm = TRUE
  )
  
  contact_pct <- safe_percent(
    total_contact,
    total_swings
  )
  
  
  # ==================================================
  # HARD CONTACT %
  # ==================================================
  #
  # Hard Contact / Balls In Play
  #
  # ==================================================
  
  total_bip <- sum(
    is_in_play,
    na.rm = TRUE
  )
  
  hard_contact_count <- sum(
    is_hard_contact,
    na.rm = TRUE
  )
  
  hard_contact_pct <- safe_percent(
    hard_contact_count,
    total_bip
  )
  
  
  # ==================================================
  # PRE-2K HEART SWING %
  # ==================================================
  
  pre2k_heart_pitches <- sum(
    is_pre2k &
      is_heart,
    na.rm = TRUE
  )
  
  pre2k_heart_swings <- sum(
    is_pre2k &
      is_heart &
      is_swing,
    na.rm = TRUE
  )
  
  pre2k_heart_swing_pct <- safe_percent(
    pre2k_heart_swings,
    pre2k_heart_pitches
  )
  
  
  # ==================================================
  # 2K HEART SWING %
  # ==================================================
  
  two_k_heart_pitches <- sum(
    is_2k &
      is_heart,
    na.rm = TRUE
  )
  
  two_k_heart_swings <- sum(
    is_2k &
      is_heart &
      is_swing,
    na.rm = TRUE
  )
  
  two_k_heart_swing_pct <- safe_percent(
    two_k_heart_swings,
    two_k_heart_pitches
  )
  
  
  # ==================================================
  # PRE-2K CHASE %
  # ==================================================
  
  pre2k_chase_zone_pitches <- sum(
    is_pre2k &
      is_chase_zone,
    na.rm = TRUE
  )
  
  pre2k_chase_swings <- sum(
    is_pre2k &
      is_chase_zone &
      is_swing,
    na.rm = TRUE
  )
  
  pre2k_chase_pct <- safe_percent(
    pre2k_chase_swings,
    pre2k_chase_zone_pitches
  )
  
  
  # ==================================================
  # 2K CHASE %
  # ==================================================
  
  two_k_chase_zone_pitches <- sum(
    is_2k &
      is_chase_zone,
    na.rm = TRUE
  )
  
  two_k_chase_swings <- sum(
    is_2k &
      is_chase_zone &
      is_swing,
    na.rm = TRUE
  )
  
  two_k_chase_pct <- safe_percent(
    two_k_chase_swings,
    two_k_chase_zone_pitches
  )
  
  
  # ==================================================
  # OUTPUT
  # ==================================================
  
  data.frame(
    
    Heart_Swing_Pct =
      round(
        heart_swing_pct,
        1
      ),
    
    Heart_Take_Pct =
      round(
        heart_take_pct,
        1
      ),
    
    Chase_Pct =
      round(
        chase_pct,
        1
      ),
    
    Shadow_Swing_Pct =
      round(
        shadow_swing_pct,
        1
      ),
    
    Overall_Swing_Pct =
      round(
        overall_swing_pct,
        1
      ),
    
    Whiff_Pct =
      round(
        whiff_pct,
        1
      ),
    
    Contact_Pct =
      round(
        contact_pct,
        1
      ),
    
    Hard_Contact_Pct =
      round(
        hard_contact_pct,
        1
      ),
    
    Pre2K_Heart_Swing_Pct =
      round(
        pre2k_heart_swing_pct,
        1
      ),
    
    TwoK_Heart_Swing_Pct =
      round(
        two_k_heart_swing_pct,
        1
      ),
    
    Pre2K_Chase_Pct =
      round(
        pre2k_chase_pct,
        1
      ),
    
    TwoK_Chase_Pct =
      round(
        two_k_chase_pct,
        1
      ),
    
    Total_Pitches =
      total_pitches,
    
    Total_Swings =
      total_swings,
    
    Total_BIP =
      total_bip,
    
    stringsAsFactors = FALSE
    
  )
  
}