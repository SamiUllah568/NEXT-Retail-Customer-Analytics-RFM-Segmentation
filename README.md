# NEXT Retail: Customer Analytics & RFM Segmentation

**SQL (PostgreSQL) + Power BI | 5,879 customers | 17.37M in revenue | 2 years of transactions**

I built this project to answer a simple question a retailer should be able to answer: *who are our best customers, and who are we about to lose?*

Using two years of real transaction data, I cleaned it in SQL, scored every customer on Recency, Frequency and Monetary value, flagged churn risk, and turned the results into an interactive Power BI dashboard with a clear action plan for each customer segment.

![Home page](Dashboards%20Screenshots/Home%20Page.png)

---

## The headline findings

- **Champions are 21.5% of customers but bring in 67.7% of revenue** (11.77M of 17.37M). They are the business.
- **Half the customer base (50.84%) has gone quiet**, meaning no purchase in the last 90 days.
- **At Risk and Lost customers make up 40% of all customers** and 100% of them are churned. They still account for about 2.25M in lifetime revenue (12.9%).
- **The UK is 82.8% of revenue** and 5,351 of 5,879 customers.
- **EIRE has only 4 customers but 616K in revenue.** These are very high-value accounts, and a market worth understanding better.
- Roughly **640 churned customers are sitting inside Loyal and Needs Attention**, so they are not flagged as At Risk or Lost, but they have still gone quiet. This is an easy group to miss.

---

## Business problem

NEXT is a UK-based online-only retailer of gifts and home décor. A large share of its customers are wholesale buyers. Leadership had no structured view of which customers drive revenue or which are disengaging, so retention and marketing spend was reactive and treated everyone the same.

The goal: identify the most valuable segments, quantify churn risk, and tell the marketing and CRM teams what to do with each group.

The full requirements are in the [Business Requirements Document](NEXT%20Gifting%20BRD.docx).

---

## Tools

| Step | Tool |
|---|---|
| Data cleaning, RFM scoring, segmentation, churn flag | PostgreSQL |
| Dashboard and analysis | Power BI |
| Documentation | BRD, this README |

---

## Dataset

**Online Retail II** from the UCI Machine Learning Repository (donated by Daqing Chen). It contains 1,067,371 transaction rows from December 2009 to December 2011 (invoice, product, quantity, price, customer ID, country).

After cleaning, the analysis table has **779,483 rows**.

---

## How I cleaned the data (SQL)

1. Combined the two yearly tables with `UNION ALL`.
2. Counted and removed exact duplicate rows.
3. Checked NULLs in every column and removed rows with no customer ID (I can't score a customer I can't identify).
4. Removed rows with zero or negative quantity (returns and cancellations).
5. Trimmed spaces and tidied product descriptions.
6. Converted `invoicedate` from text to a proper timestamp.
7. Removed test products.
8. Reviewed zero-priced rows for data quality.
9. Validated row counts after every step.

The full SQL (cleaning, RFM scoring, segmentation and churn flag) is in [`WillowWren_Analytics.sql`](WillowWren_Analytics.sql).

---

## RFM scoring and segments

For every customer I calculated:

- **Recency:** days since their last purchase, measured from the reference date 2011-12-10
- **Frequency:** number of distinct invoices
- **Monetary:** total revenue (`quantity × price`)

**Scoring (1 to 5):**

- Recency and Monetary use quintiles (`NTILE(5)`).
- Frequency uses **fixed thresholds** (1, 2, 3 to 4, 5 to 9, 10+ orders). I switched to this after noticing that thousands of customers have exactly one order, and `NTILE` splits tied values into different buckets. Fixed thresholds mean everyone with the same number of orders gets the same score.

**Segments:**

| Segment | Rule |
|---|---|
| Champions | R ≥ 4, F ≥ 4, M ≥ 4 |
| New | R ≥ 4, F = 1 |
| At Risk | R ≤ 2, F ≥ 3 |
| Lost | R ≤ 2, F ≤ 2 |
| Loyal | R ≥ 3, F ≥ 3 |
| Needs Attention | Everyone else |

**Churn definition:** no purchase in the last **90 days**. I kept this as a fixed, easy-to-explain rule, as agreed in the BRD, rather than a statistically derived cutoff.

---

## Results by segment

| Segment | Customers | % of customers | Revenue | % of revenue | Churned |
|---|---:|---:|---:|---:|---:|
| Champions | 1,265 | 21.52% | 11,765,378 | 67.72% | 0% |
| Loyal | 1,338 | 22.76% | 2,716,443 | 15.63% | 31.09% |
| At Risk | 708 | 12.04% | 1,521,050 | 8.75% | 100% |
| Lost | 1,644 | 27.96% | 725,082 | 4.17% | 100% |
| Needs Attention | 686 | 11.67% | 566,120 | 3.26% | 32.22% |
| New | 238 | 4.05% | 80,505 | 0.46% | 0% |
| **Total** | **5,879** | | **17,374,578** | | **50.84%** |

### By country (top markets)

| Country | Customers | Revenue | Churned |
|---|---:|---:|---:|
| United Kingdom | 5,351 | 14,389,210 | 51.15% |
| EIRE | 4 | 616,369 | 50.00% |
| Netherlands | 22 | 554,038 | 72.73% |
| Germany | 107 | 425,940 | 35.51% |
| France | 93 | 347,091 | 35.48% |
| Australia | 13 | 158,776 | 61.54% |
| Spain | 41 | 120,362 | 43.90% |

The Netherlands stands out: only 22 customers but a 72.7% churn rate and over half a million in revenue.

---

## Recommended actions

**Champions (1,265)** are the most valuable group. Reward them: early access, loyalty perks, thank-you gifts, a dedicated contact for the biggest accounts. Losing even a few of them would hurt more than losing hundreds of Lost customers.

**Loyal (1,338)** are steady and valuable. Keep them engaged and encourage upgrades toward Champion with bundles and repeat-order incentives. Pay attention to the roughly 416 who have already gone quiet.

**At Risk (708)** used to buy often and have stopped. They are the best win-back opportunity. Send personalised win-back offers and discounts quickly, before they become Lost.

**Lost (1,644)** are inactive and low value on average. Run a low-cost reactivation campaign (a discount or "we miss you" email) and stop spending heavily on them if it doesn't work.

**Needs Attention (686)** buy recently but rarely, and about 32% have already churned. Use targeted offers and product suggestions to build a second and third purchase.

**New (238)** have just joined. Send a welcome message and a small gift to encourage a second order, because that is where repeat customers are made.

**Markets:** look more closely at EIRE (4 high-value accounts) and the Netherlands (high churn). Protect those accounts first, then test whether similar buyers exist in those markets.

---

## The dashboard

**Home page:** navigation and a quick explanation of R, F and M.

**Revenue & Customers Overview:** KPIs (total revenue, customers, quantity sold, UK revenue share, churn %), revenue and customers by segment, and trends by month, quarter and year. Toggle between the Revenue and Customers views.

**Customer RFM & Country Analysis:** segment and country performance tables with average R, F and M scores, churn % and churn trends. Toggle between the Segment and Country views.

Every page has slicers for month, quarter, year, country, segment and churn flag.

| Revenue overview | Customers overview |
|---|---|
| ![Revenue](Dashboards%20Screenshots/Revenue%20Overview.png) | ![Customers](Dashboards%20Screenshots/Customers%20Overview.png) |

| Segment analysis | Country analysis |
|---|---|
| ![Segments](Dashboards%20Screenshots/Customer%20RFM%20Segment%20Analysis.png) | ![Country](Dashboards%20Screenshots/Country%20Analysis.png) |

---

## Limitations (what you should know before relying on these numbers)

I'd rather be upfront about these than have you find them later.

- **Churn and segments are linked by design.** Both use recency, so At Risk and Lost are 100% churned and Champions are 0% churned automatically. The useful signal is the *size* and *revenue* of each group, plus the churned customers hiding inside Loyal and Needs Attention.
- **Churn trends over time are biased.** The churn-by-month, quarter and year charts fall toward 2011 because recent customers haven't had time to churn yet. It doesn't mean retention improved.
- **Wholesale and retail customers are not separated** because the data doesn't clearly distinguish them. A few large wholesale accounts (like the 4 in EIRE) can dominate revenue.
- **Non-product lines** such as manual adjustments may still be included in revenue.
- **Zero-price rows** were reviewed but kept in the analysis table.
- **Historical data only.** No promotions, seasonality or forecasting. This is segmentation, not a predictive churn model.
- The reference date is fixed at 2011-12-10, the last day in the data.

## What I'd do next

- Separate wholesale and retail customers
- Add a revenue-at-risk metric by segment
- Build a predictive churn model
- Add customer lifetime value
- Set up automatic monthly refreshes

---

## Repository structure

```
├── WillowWren_Analytics.sql        # cleaning, RFM scoring, segmentation, churn flag
├── 01_clean_data.csv               # cleaned transaction data
├── 02_rfm_segmentation.csv         # customer-level RFM scores, segments, churn flag
├── NEXT Retail Gifting.pbix        # Power BI dashboard
├── NEXT Gifting BRD.docx           # Business Requirements Document
├── NEXT Gifting Dataset.zip        # raw Online Retail II data
├── Dashboards Screenshots/
│   ├── Home Page.png
│   ├── Revenue Overview.png
│   ├── Customers Overview.png
│   ├── Customer RFM Segment Analysis.png
│   └── Country Analysis.png
└── README.md
```

## How to reproduce

1. Unzip `NEXT Gifting Dataset.zip` (the raw Online Retail II data from the UCI Machine Learning Repository).
2. Create a PostgreSQL database and load the two yearly sheets into `next_1` and `next_2`.
3. Run `WillowWren_Analytics.sql` from top to bottom.
4. Open `NEXT Retail Gifting.pbix` in Power BI, point it at your PostgreSQL database, and refresh.

Prefer to skip the SQL? `01_clean_data.csv` and `02_rfm_segmentation.csv` hold the cleaned data and the final customer segments.

---

## About me

I'm **Sami Ullah**, a data analyst working with SQL and Power BI. I build projects that go from raw data to decisions a business can act on.

GitHub: [SamiUllah568](https://github.com/SamiUllah568)

*If you'd like something similar for your own customer data, I'd be happy to talk.*
