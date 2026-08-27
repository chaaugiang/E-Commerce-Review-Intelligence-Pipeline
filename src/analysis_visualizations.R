library(tidyverse)
library(lubridate)

data_dir <- "data"
figure_dir <- "outputs/figures"

if (!dir.exists(figure_dir)) dir.create(figure_dir)

# Shared look-and-feel for every figure in the report
theme_report <- theme_minimal(base_size = 12) +
  theme(
    plot.title    = element_text(face = "bold", size = 13),
    plot.subtitle = element_text(colour = "grey35"),
    panel.grid.minor = element_blank()
  )

save_figure <- function(plot, filename, width = 8, height = 5) {
  ggsave(
    filename = file.path(figure_dir, filename),
    plot     = plot,
    width    = width,
    height   = height,
    dpi      = 300
  )
}


# ------------------------------------------------------------
# 1. Verified Purchase Rating Analysis
# ------------------------------------------------------------
q6 <- read_csv(
  file.path(data_dir, "q6_avg_rating_by_verified.csv"),
  show_col_types = FALSE
)

# "Overall" is the aggregate of the two groups, so it is drawn as a
# reference line rather than as a third bar.
overall_rating <- q6 %>%
  filter(purchase_group == "Overall") %>%
  pull(avg_rating)

q6_groups <- q6 %>%
  filter(purchase_group != "Overall") %>%
  mutate(purchase_group = fct_relevel(purchase_group, "Verified", "Non-Verified"))

p6 <- ggplot(q6_groups, aes(x = purchase_group, y = avg_rating, fill = purchase_group)) +
  geom_col(width = 0.6) +
  geom_hline(yintercept = overall_rating, linetype = "dashed", colour = "grey30") +
  annotate(
    "text",
    x = 0.55, y = overall_rating + 0.15,
    label = paste0("Overall = ", sprintf("%.2f", overall_rating)),
    hjust = 0, size = 3.5, colour = "grey30"
  ) +
  geom_text(aes(label = sprintf("%.2f", avg_rating)), vjust = -0.6, size = 4) +
  scale_fill_manual(values = c("Verified" = "#2C7FB8", "Non-Verified" = "#D95F02")) +
  scale_y_continuous(limits = c(0, 5), expand = expansion(mult = c(0, 0.05))) +
  labs(
    title    = "Verified purchases rate products about 0.3 stars higher",
    subtitle = "Average star rating by purchase type; dashed line is the overall average",
    x        = NULL,
    y        = "Average star rating"
  ) +
  theme_report +
  theme(legend.position = "none")

print(p6)
save_figure(p6, "q6_avg_rating_by_verified.png")


# ------------------------------------------------------------
#  2. Rating Distribution Analysis
# ------------------------------------------------------------
q7 <- read_csv(
  file.path(data_dir, "q7_rating_distribution.csv"),
  show_col_types = FALSE
) %>%
  rename(n_reviews = number_reviews) %>%   # match the naming used elsewhere
  mutate(pct = n_reviews / sum(n_reviews))

p7 <- ggplot(q7, aes(x = factor(star_rating), y = n_reviews)) +
  geom_col(fill = "#2C7FB8", width = 0.7) +
  geom_text(
    aes(label = paste0(
      scales::comma(n_reviews), "\n",
      scales::percent(pct, accuracy = 0.1)
    )),
    vjust = -0.3, size = 3.3, lineheight = 0.95
  ) +
  scale_y_continuous(
    labels = scales::comma,
    expand = expansion(mult = c(0, 0.15))
  ) +
  labs(
    title    = "Ratings are strongly left-skewed: over 60% of reviews are 5 stars",
    subtitle = "Number of reviews by star rating (share of all reviews in parentheses)",
    x        = "Star rating",
    y        = "Number of reviews"
  ) +
  theme_report

print(p7)
save_figure(p7, "q7_rating_distribution.png")


# ------------------------------------------------------------
# 3. Reviewer Rating Behavior
# ------------------------------------------------------------
# The two groups contain different numbers of reviews, so raw counts
# cannot answer "does the distribution change?". Shares within each
# group are compared instead.
q8 <- read_csv(
  file.path(data_dir, "q8_rating_distribution_bias.csv"),
  show_col_types = FALSE
) %>%
  mutate(group_label = fct_relevel(group_label, "All Reviewers", "Without Biased Reviewers")) %>%
  group_by(group_label) %>%
  mutate(pct = n_reviews / sum(n_reviews)) %>%
  ungroup()

dodge <- position_dodge(width = 0.75)

p8 <- ggplot(q8, aes(x = factor(star_rating), y = pct, fill = group_label)) +
  geom_col(position = dodge, width = 0.7) +
  geom_text(
    aes(label = scales::percent(pct, accuracy = 0.1)),
    position = dodge, vjust = -0.4, size = 3
  ) +
  scale_fill_manual(values = c(
    "All Reviewers"            = "#9EBCDA",
    "Without Biased Reviewers" = "#2C7FB8"
  )) +
  scale_y_continuous(labels = scales::percent, expand = expansion(mult = c(0, 0.12))) +
  labs(
    title    = "Excluding biased reviewers shifts share away from 5 stars",
    subtitle = "Share of reviews at each star rating, computed within each group",
    x        = "Star rating",
    y        = "Share of reviews",
    fill     = NULL
  ) +
  theme_report +
  theme(legend.position = "top")

print(p8)
save_figure(p8, "q8_rating_distribution_bias.png")

# Companion chart: percentage-point change per star rating, which makes
# the size and direction of the shift explicit.
q8_delta <- q8 %>%
  select(star_rating, group_label, pct) %>%
  pivot_wider(names_from = group_label, values_from = pct) %>%
  mutate(delta_pp = (`Without Biased Reviewers` - `All Reviewers`) * 100)

p8_delta <- ggplot(q8_delta, aes(x = factor(star_rating), y = delta_pp,
                                 fill = delta_pp > 0)) +
  geom_col(width = 0.6) +
  geom_hline(yintercept = 0, colour = "grey40") +
  geom_text(
    aes(label = sprintf("%+.1f pp", delta_pp),
        vjust = ifelse(delta_pp > 0, -0.5, 1.3)),
    size = 3.5
  ) +
  scale_fill_manual(values = c("TRUE" = "#2C7FB8", "FALSE" = "#D95F02")) +
  labs(
    title    = "Where the distribution moves after removing biased reviewers",
    subtitle = "Change in share of reviews, in percentage points",
    x        = "Star rating",
    y        = "Change in share (pp)"
  ) +
  theme_report +
  theme(legend.position = "none")

print(p8_delta)
save_figure(p8_delta, "q8_rating_distribution_shift.png")


# ------------------------------------------------------------
# 4. Review Seasonality Analysis
# ------------------------------------------------------------
q9 <- read_csv(
  file.path(data_dir, "q9_monthly_reviews.csv"),
  show_col_types = FALSE
) %>%
  mutate(review_date = as.Date(sprintf("%04d-%02d-01", review_year, review_month)))

# Months with zero reviews are absent from the SQL output. Inserting them
# as NA keeps the line from drawing straight through the gaps.
q9_full <- q9 %>%
  complete(review_date = seq(min(review_date), max(review_date), by = "month")) %>%
  mutate(
    review_year  = year(review_date),
    review_month = month(review_date)
  )

# --- 9a: full history on a log scale --------------------------------
# Volume grows from single digits in 1998 to ~100,000 per month in 2015,
# so a linear axis would flatten the first decade into the baseline.
p9_trend <- ggplot(q9_full, aes(x = review_date, y = n_reviews)) +
  geom_line(colour = "#2C7FB8", linewidth = 0.6) +
  scale_y_log10(labels = scales::comma) +
  scale_x_date(date_breaks = "2 years", date_labels = "%Y") +
  labs(
    title    = "Review volume grew by roughly five orders of magnitude",
    subtitle = "Monthly number of reviews, log scale (gaps = months with no reviews)",
    x        = NULL,
    y        = "Number of reviews (log scale)"
  ) +
  theme_report

print(p9_trend)
save_figure(p9_trend, "q9_monthly_volume_trend.png")

# --- 9b: month-of-year profile for recent, high-volume years --------
# 2015 stops in August, so it is excluded from the seasonality check.
q9_recent <- q9 %>%
  filter(review_year >= 2010, review_year <= 2014)

p9_season <- ggplot(q9_recent, aes(x = review_month, y = n_reviews,
                                   colour = factor(review_year))) +
  geom_line(linewidth = 0.7) +
  geom_point(size = 1.6) +
  scale_x_continuous(breaks = 1:12, labels = month.abb) +
  scale_y_continuous(labels = scales::comma) +
  scale_colour_brewer(palette = "Blues", direction = 1) +
  labs(
    title    = "Every year follows the same shape: a spring trough and a December peak",
    subtitle = "Monthly review counts, 2010–2014 (2015 excluded: partial year)",
    x        = NULL,
    y        = "Number of reviews",
    colour   = "Year"
  ) +
  theme_report

print(p9_season)
save_figure(p9_season, "q9_seasonality_by_year.png")

# --- 9c: seasonal index, growth removed -----------------------------
# Each month is expressed relative to its own year's monthly average, so
# the underlying growth trend does not mask the seasonal pattern.
q9_index <- q9 %>%
  filter(review_year >= 2010, review_year <= 2014) %>%
  group_by(review_year) %>%
  mutate(seasonal_index = n_reviews / mean(n_reviews)) %>%
  ungroup()

p9_index <- ggplot(q9_index, aes(x = factor(review_month), y = seasonal_index)) +
  geom_hline(yintercept = 1, linetype = "dashed", colour = "grey50") +
  geom_boxplot(fill = "#9EBCDA", outlier.size = 1) +
  scale_x_discrete(labels = month.abb) +
  labs(
    title    = "December runs ~65% above an average month; Feb–Jun run ~20% below",
    subtitle = "Monthly reviews relative to that year's monthly average, 2010–2014",
    x        = NULL,
    y        = "Seasonal index (1.0 = year's average month)"
  ) +
  theme_report

print(p9_index)
save_figure(p9_index, "q9_seasonal_index.png")
