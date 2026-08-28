# ==================================================
# GOOGLE SHEETS DATABASE FUNCTIONS
# ==================================================
#
# This file contains low-level functions for reading
# and writing the Swing Decision Platform database.
#
# It does NOT contain Shiny reactive logic.
# app.R will tell these functions what data to save.
# ==================================================


# ==================================================
# NEXT OPEN ROW
# ==================================================

gs_get_next_open_row <- function(
    sheet_url,
    sheet_name,
    id_column = "A",
    max_row = 5001
) {
  
  existing_ids <- googlesheets4::read_sheet(
    
    ss = sheet_url,
    
    sheet = sheet_name,
    
    range = paste0(
      id_column,
      "1:",
      id_column,
      max_row
    ),
    
    col_names = FALSE
    
  )
  
  used_rows <- sum(
    
    !is.na(existing_ids[[1]]) &
      existing_ids[[1]] != ""
    
  )
  
  used_rows + 1
}


# ==================================================
# READ SESSIONS
# ==================================================

gs_read_sessions <- function(
    sheet_url
) {
  
  sessions_data <- googlesheets4::read_sheet(
    
    ss = sheet_url,
    
    sheet = "Sessions",
    
    range = "A1:L101",
    
    col_names = TRUE
    
  )
  
  if (
    nrow(sessions_data) == 0 ||
    !"Session_ID" %in% names(sessions_data)
  ) {
    
    return(
      data.frame()
    )
    
  }
  
  sessions_data <- sessions_data[
    
    !is.na(
      sessions_data$Session_ID
    ) &
      
      sessions_data$Session_ID != "",
    
  ]
  
  sessions_data
}


# ==================================================
# WRITE SESSION
# ==================================================

gs_write_session <- function(
    sheet_url,
    session_data
) {
  
  next_row <- gs_get_next_open_row(
    
    sheet_url = sheet_url,
    
    sheet_name = "Sessions",
    
    id_column = "A",
    
    max_row = 101
    
  )
  
  googlesheets4::range_write(
    
    ss = sheet_url,
    
    data = session_data,
    
    sheet = "Sessions",
    
    range = paste0(
      "A",
      next_row,
      ":L",
      next_row
    ),
    
    col_names = FALSE
    
  )
  
  next_row
}


# ==================================================
# WRITE PITCH
# ==================================================

gs_write_pitch <- function(
    sheet_url,
    pitch_data_main,
    pitch_score_data,
    pitch_data_end
) {
  
  next_row <- gs_get_next_open_row(
    
    sheet_url = sheet_url,
    
    sheet_name = "Pitches",
    
    id_column = "A",
    
    max_row = 5001
    
  )
  
  # ----------------------------------------------
  # A:S
  #
  # Main pitch information.
  # ----------------------------------------------
  
  googlesheets4::range_write(
    
    ss = sheet_url,
    
    data = pitch_data_main,
    
    sheet = "Pitches",
    
    range = paste0(
      "A",
      next_row,
      ":S",
      next_row
    ),
    
    col_names = FALSE
    
  )
  
  googlesheets4::range_write(
    
    ss = sheet_url,
    
    data = pitch_score_data,
    
    sheet = "Pitches",
    
    range = paste0(
      "T",
      next_row,
      ":V",
      next_row
    ),
    
    col_names = FALSE
  )
  
  # ----------------------------------------------
  # Z:AA
  #
  # Timestamp + Notes.
  #
  # IMPORTANT:
  # T:Y are intentionally untouched because
  # those columns contain scoring formulas.
  # ----------------------------------------------
  
  googlesheets4::range_write(
    
    ss = sheet_url,
    
    data = pitch_data_end,
    
    sheet = "Pitches",
    
    range = paste0(
      "Z",
      next_row,
      ":AA",
      next_row
    ),
    
    col_names = FALSE
    
  )
  
  next_row
}


# ==================================================
# WRITE PLATE APPEARANCE
# ==================================================

gs_write_pa <- function(
    sheet_url,
    pa_data
) {
  
  next_row <- gs_get_next_open_row(
    
    sheet_url = sheet_url,
    
    sheet_name = "Plate_Appearances",
    
    id_column = "A",
    
    max_row = 1001
    
  )
  
  googlesheets4::range_write(
    
    ss = sheet_url,
    
    data = pa_data,
    
    sheet = "Plate_Appearances",
    
    range = paste0(
      "A",
      next_row,
      ":U",
      next_row
    ),
    
    col_names = FALSE
    
  )
  
  next_row
}


# ==================================================
# READ SESSION PITCH COUNTERS
# ==================================================

gs_read_pitch_counters <- function(
    sheet_url
) {
  
  googlesheets4::read_sheet(
    
    ss = sheet_url,
    
    sheet = "Pitches",
    
    range = "C1:E5001",
    
    col_names = TRUE
    
  )
}


# ==================================================
# READ SESSION PA COUNTERS
# ==================================================

gs_read_pa_counters <- function(
    sheet_url
) {
  
  googlesheets4::read_sheet(
    
    ss = sheet_url,
    
    sheet = "Plate_Appearances",
    
    range = "C1:D1001",
    
    col_names = TRUE
    
  )
}

# ==================================================
# APP COMPATIBILITY WRAPPER
# ==================================================

get_next_open_row <- function(
    sheet_name,
    id_column,
    max_row
) {
  
  gs_get_next_open_row(
    sheet_url = SHEET_URL,
    sheet_name = sheet_name,
    id_column = id_column,
    max_row = max_row
  )
  
}

# ==================================================
# READ PLAYERS
# ==================================================

gs_read_players <- function(
    sheet_url
) {
  
  players_data <- googlesheets4::read_sheet(
    
    ss = sheet_url,
    
    sheet = "Players",
    
    col_names = TRUE
    
  )
  
  if (
    nrow(players_data) == 0 ||
    !"Player_ID" %in% names(players_data)
  ) {
    
    return(
      data.frame()
    )
    
  }
  
  players_data <- players_data[
    
    !is.na(
      players_data$Player_ID
    ) &
      
      players_data$Player_ID != "",
    
  ]
  
  players_data
}

# ==================================================
# READ PITCHES
# ==================================================

gs_read_pitches <- function(
    sheet_url
) {
  
  pitches_data <- googlesheets4::read_sheet(
    
    ss = sheet_url,
    
    sheet = "Pitches",
    
    range = "A1:AC5001",
    
    col_names = TRUE
    
  )
  
  if (
    nrow(pitches_data) == 0 ||
    !"Pitch_ID" %in% names(pitches_data)
  ) {
    
    return(
      data.frame()
    )
    
  }
  
  pitches_data <- pitches_data[
    
    !is.na(
      pitches_data$Pitch_ID
    ) &
      
      pitches_data$Pitch_ID != "",
    
  ]
  
  pitches_data
}