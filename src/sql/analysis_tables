-- ============================================================
-- Marketplace Review Intelligence
-- Analysis-Ready SQL Tables
-- ============================================================


-- ------------------------------------------------------------
-- 1. Verified Purchase Rating Analysis
-- ------------------------------------------------------------

DROP TABLE IF EXISTS avg_rating_by_verified;

CREATE TABLE avg_rating_by_verified AS
SELECT
    'Overall' AS purchase_group,
    AVG(star_rating) AS avg_rating
FROM reviews

UNION ALL

SELECT
    'Verified' AS purchase_group,
    AVG(star_rating) AS avg_rating
FROM reviews
WHERE verified_purchase = 1

UNION ALL

SELECT
    'Non-Verified' AS purchase_group,
    AVG(star_rating) AS avg_rating
FROM reviews
WHERE verified_purchase = 0;


-- ------------------------------------------------------------
-- 2. Rating Distribution Analysis
-- ------------------------------------------------------------

DROP TABLE IF EXISTS rating_distribution;

CREATE TABLE rating_distribution AS
SELECT
    star_rating,
    COUNT(*) AS number_reviews
FROM reviews
GROUP BY star_rating
ORDER BY star_rating;


-- ------------------------------------------------------------
-- 3. Reviewer Rating Behavior
-- ------------------------------------------------------------

-- A reviewer is flagged as potentially biased when they have
-- at least five reviews and at least 80% of those ratings are
-- at either extreme of the scale (1 or 5 stars).

DROP TABLE IF EXISTS rating_distribution_bias;

CREATE TABLE rating_distribution_bias AS

SELECT
    star_rating,
    COUNT(*) AS n_reviews,
    'All Reviewers' AS group_label
FROM reviews
GROUP BY star_rating

UNION ALL

SELECT
    r.star_rating,
    COUNT(*) AS n_reviews,
    'Without Potentially Biased Reviewers' AS group_label
FROM reviews AS r

LEFT JOIN (
    SELECT customer_id
    FROM reviews
    GROUP BY customer_id
    HAVING COUNT(*) >= 5
       AND SUM(
            CASE
                WHEN star_rating IN (1, 5) THEN 1
                ELSE 0
            END
       ) / COUNT(*) >= 0.80
) AS biased
    ON r.customer_id = biased.customer_id

WHERE biased.customer_id IS NULL

GROUP BY r.star_rating
ORDER BY star_rating;


-- ------------------------------------------------------------
-- 4. Monthly Review Volume
-- ------------------------------------------------------------

DROP TABLE IF EXISTS monthly_reviews;

CREATE TABLE monthly_reviews AS
SELECT
    YEAR(review_date) AS review_year,
    MONTH(review_date) AS review_month,
    COUNT(*) AS n_reviews
FROM reviews
GROUP BY
    YEAR(review_date),
    MONTH(review_date)
ORDER BY
    review_year,
    review_month;
