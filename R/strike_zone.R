# ==================================================
# LOCKED STRIKE ZONE COMPONENT
# ==================================================
# IMPORTANT:
# This is the finalized pitch-location geometry.
# Do not change these coordinates unless intentionally
# redesigning the strike-zone system.
#
# UPDATE:
# The visual geometry below is unchanged.
# Each click now also records the exact location of the
# click inside the SVG so the report heat maps can use
# true spatial pitch-location data.
#
# Inputs sent to Shiny:
#
#   input$zone_click
#       Existing zone number. This keeps the current
#       scoring/charting workflow exactly the same.
#
#   input$zone_click_location
#       A list containing:
#         zone   = clicked zone
#         x      = raw SVG x-coordinate
#         y      = raw SVG y-coordinate
#         x_norm = normalized x position from 0 to 1
#         y_norm = normalized y position from 0 to 1
#
# The normalized values are what we will save to:
#   Location_X
#   Location_Y
# ==================================================

build_strike_zone <- function(selected_zone_value = NULL) {
  
  zone_rect <- function(
    zone,
    x,
    y,
    width,
    height,
    fill,
    font_size = 18
  ) {
    
    selected <-
      !is.null(selected_zone_value) &&
      selected_zone_value == zone
    
    stroke_color <-
      if (selected) {
        "#A7191F"
      } else {
        "#888888"
      }
    
    stroke_width <-
      if (selected) {
        4
      } else {
        1.2
      }
    
    click_js <- sprintf(
      paste0(
        "(function(evt){",
        "var svg = evt.currentTarget.ownerSVGElement;",
        "var pt = svg.createSVGPoint();",
        "pt.x = evt.clientX;",
        "pt.y = evt.clientY;",
        "var svgPt = pt.matrixTransform(svg.getScreenCTM().inverse());",
        "Shiny.setInputValue(",
        "'zone_click', %s, {priority:'event'}",
        ");",
        "Shiny.setInputValue(",
        "'zone_click_location', ",
        "{",
        "zone:%s,",
        "x:svgPt.x,",
        "y:svgPt.y,",
        "x_norm:svgPt.x/520,",
        "y_norm:svgPt.y/520,",
        "nonce:Date.now()",
        "},",
        "{priority:'event'}",
        ");",
        "})(event);"
      ),
      zone,
      zone
    )
    
    shiny::tags$g(
      
      onclick = click_js,
      
      style = "cursor:pointer;",
      
      shiny::tags$rect(
        x = x,
        y = y,
        width = width,
        height = height,
        fill = fill,
        stroke = stroke_color,
        `stroke-width` = stroke_width
      ),
      
      shiny::tags$text(
        x = x + width / 2,
        y = y + height / 2 + 6,
        `text-anchor` = "middle",
        `font-size` = font_size,
        `font-weight` = "600",
        fill = "#333333",
        `pointer-events` = "none",
        zone
      )
    )
  }
  
  # ==================================================
  # FINALIZED GEOMETRY
  # ==================================================
  
  outer_left <- 20
  outer_right <- 500
  
  waste_left_edge <- 145
  waste_right_edge <- 375
  
  outer_top <- 20
  waste_top_edge <- 105
  waste_bottom_edge <- 405
  outer_bottom <- 490
  
  chase_left <- 105
  chase_right <- 415
  
  chase_col_1 <- 200
  chase_col_2 <- 320
  
  chase_top <- 105
  chase_mid_top <- 200
  chase_mid_bottom <- 320
  chase_bottom <- 405
  
  shadow_left <- 182
  shadow_right <- 338
  
  shadow_top <- 175
  shadow_top_bottom <- 225
  
  shadow_bottom_top <- 310
  shadow_bottom <- 350
  
  heart_left <- 215
  heart_right <- 305
  
  heart_col_1 <- 245
  heart_col_2 <- 275
  
  heart_top <- 225
  heart_row_1 <- 253
  heart_row_2 <- 282
  heart_bottom <- 310
  
  strike_left <- 202
  strike_right <- 318
  
  strike_top <- 200
  strike_bottom <- 335
  
  shiny::tags$svg(
    
    width = "100%",
    viewBox = "0 0 520 520",
    
    style = "
      background:#f7f4ef;
      border:1px solid #d8d4ce;
    ",
    
    # ==================================================
    # WASTE
    # ==================================================
    
    zone_rect(
      31,
      outer_left,
      outer_top,
      waste_left_edge - outer_left,
      waste_top_edge - outer_top,
      "#f2f2f2"
    ),
    
    zone_rect(
      32,
      waste_left_edge,
      outer_top,
      waste_right_edge - waste_left_edge,
      waste_top_edge - outer_top,
      "#f2f2f2"
    ),
    
    zone_rect(
      33,
      waste_right_edge,
      outer_top,
      outer_right - waste_right_edge,
      waste_top_edge - outer_top,
      "#f2f2f2"
    ),
    
    zone_rect(
      34,
      outer_left,
      waste_top_edge,
      chase_left - outer_left,
      waste_bottom_edge - waste_top_edge,
      "#f2f2f2"
    ),
    
    zone_rect(
      36,
      chase_right,
      waste_top_edge,
      outer_right - chase_right,
      waste_bottom_edge - waste_top_edge,
      "#f2f2f2"
    ),
    
    zone_rect(
      37,
      outer_left,
      waste_bottom_edge,
      waste_left_edge - outer_left,
      outer_bottom - waste_bottom_edge,
      "#f2f2f2"
    ),
    
    zone_rect(
      38,
      waste_left_edge,
      waste_bottom_edge,
      waste_right_edge - waste_left_edge,
      outer_bottom - waste_bottom_edge,
      "#f2f2f2"
    ),
    
    zone_rect(
      39,
      waste_right_edge,
      waste_bottom_edge,
      outer_right - waste_right_edge,
      outer_bottom - waste_bottom_edge,
      "#f2f2f2"
    ),
    
    # ==================================================
    # CHASE
    # ==================================================
    
    zone_rect(
      21,
      chase_left,
      chase_top,
      chase_col_1 - chase_left,
      chase_mid_top - chase_top,
      "#fff2a8"
    ),
    
    zone_rect(
      22,
      chase_col_1,
      chase_top,
      chase_col_2 - chase_col_1,
      chase_mid_top - chase_top,
      "#fff2a8"
    ),
    
    zone_rect(
      23,
      chase_col_2,
      chase_top,
      chase_right - chase_col_2,
      chase_mid_top - chase_top,
      "#fff2a8"
    ),
    
    zone_rect(
      24,
      chase_left,
      chase_mid_top,
      chase_col_1 - chase_left,
      chase_mid_bottom - chase_mid_top,
      "#fff2a8"
    ),
    
    zone_rect(
      26,
      chase_col_2,
      chase_mid_top,
      chase_right - chase_col_2,
      chase_mid_bottom - chase_mid_top,
      "#fff2a8"
    ),
    
    zone_rect(
      27,
      chase_left,
      chase_mid_bottom,
      chase_col_1 - chase_left,
      chase_bottom - chase_mid_bottom,
      "#fff2a8"
    ),
    
    zone_rect(
      28,
      chase_col_1,
      chase_mid_bottom,
      chase_col_2 - chase_col_1,
      chase_bottom - chase_mid_bottom,
      "#fff2a8"
    ),
    
    zone_rect(
      29,
      chase_col_2,
      chase_mid_bottom,
      chase_right - chase_col_2,
      chase_bottom - chase_mid_bottom,
      "#fff2a8"
    ),
    
    # ==================================================
    # SHADOW
    # ==================================================
    
    zone_rect(
      11,
      shadow_left,
      shadow_top,
      52,
      shadow_top_bottom - shadow_top,
      "#f3d6db",
      16
    ),
    
    zone_rect(
      12,
      shadow_left + 52,
      shadow_top,
      52,
      shadow_top_bottom - shadow_top,
      "#f3d6db",
      16
    ),
    
    zone_rect(
      13,
      shadow_left + 104,
      shadow_top,
      shadow_right - (shadow_left + 104),
      shadow_top_bottom - shadow_top,
      "#f3d6db",
      16
    ),
    
    zone_rect(
      14,
      shadow_left,
      shadow_top_bottom,
      heart_left - shadow_left,
      shadow_bottom_top - shadow_top_bottom,
      "#f3d6db",
      16
    ),
    
    zone_rect(
      16,
      heart_right,
      shadow_top_bottom,
      shadow_right - heart_right,
      shadow_bottom_top - shadow_top_bottom,
      "#f3d6db",
      16
    ),
    
    zone_rect(
      17,
      shadow_left,
      shadow_bottom_top,
      52,
      shadow_bottom - shadow_bottom_top,
      "#f3d6db",
      16
    ),
    
    zone_rect(
      18,
      shadow_left + 52,
      shadow_bottom_top,
      52,
      shadow_bottom - shadow_bottom_top,
      "#f3d6db",
      16
    ),
    
    zone_rect(
      19,
      shadow_left + 104,
      shadow_bottom_top,
      shadow_right - (shadow_left + 104),
      shadow_bottom - shadow_bottom_top,
      "#f3d6db",
      16
    ),
    
    # ==================================================
    # HEART
    # ==================================================
    
    zone_rect(
      1,
      heart_left,
      heart_top,
      heart_col_1 - heart_left,
      heart_row_1 - heart_top,
      "#d7a6d5",
      15
    ),
    
    zone_rect(
      2,
      heart_col_1,
      heart_top,
      heart_col_2 - heart_col_1,
      heart_row_1 - heart_top,
      "#d7a6d5",
      15
    ),
    
    zone_rect(
      3,
      heart_col_2,
      heart_top,
      heart_right - heart_col_2,
      heart_row_1 - heart_top,
      "#d7a6d5",
      15
    ),
    
    zone_rect(
      4,
      heart_left,
      heart_row_1,
      heart_col_1 - heart_left,
      heart_row_2 - heart_row_1,
      "#d7a6d5",
      15
    ),
    
    zone_rect(
      5,
      heart_col_1,
      heart_row_1,
      heart_col_2 - heart_col_1,
      heart_row_2 - heart_row_1,
      "#d7a6d5",
      15
    ),
    
    zone_rect(
      6,
      heart_col_2,
      heart_row_1,
      heart_right - heart_col_2,
      heart_row_2 - heart_row_1,
      "#d7a6d5",
      15
    ),
    
    zone_rect(
      7,
      heart_left,
      heart_row_2,
      heart_col_1 - heart_left,
      heart_bottom - heart_row_2,
      "#d7a6d5",
      15
    ),
    
    zone_rect(
      8,
      heart_col_1,
      heart_row_2,
      heart_col_2 - heart_col_1,
      heart_bottom - heart_row_2,
      "#d7a6d5",
      15
    ),
    
    zone_rect(
      9,
      heart_col_2,
      heart_row_2,
      heart_right - heart_col_2,
      heart_bottom - heart_row_2,
      "#d7a6d5",
      15
    ),
    
    # ==================================================
    # STRIKE ZONE BORDER
    # ==================================================
    
    shiny::tags$rect(
      x = strike_left,
      y = strike_top,
      width = strike_right - strike_left,
      height = strike_bottom - strike_top,
      fill = "none",
      stroke = "#688b45",
      `stroke-width` = 3,
      `stroke-dasharray` = "6 4",
      `pointer-events` = "none"
    ),
    
    # ==================================================
    # HOME PLATE
    # ==================================================
    
    shiny::tags$polygon(
      points = "
        235,470
        285,470
        295,480
        260,495
        225,480
      ",
      fill = "#ffffff",
      stroke = "#222222",
      `stroke-width` = 2,
      `pointer-events` = "none"
    )
  )
}
