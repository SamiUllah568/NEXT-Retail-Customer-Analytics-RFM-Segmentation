# NEXT Retail: Customer Analytics & RFM Segmentation

*Which customers are worth fighting for, and which ones have already slipped away?*

NEXT is a UK online shop selling gifts and home decor. Two years of its orders sit behind this project, around 5,900 customers in total. I cleaned the raw transactions in PostgreSQL, scored every customer on recency, frequency and spend (RFM), and built a three-page Power BI report that tells the marketing team who to reward, who to win back and who to welcome.

![Home page](Dashboards%20Screenshots/Home%20Page.png)

**5,879 customers  |  17.37M revenue  |  50.84% haven't bought in the last 90 days**

There is also a short visual write-up of the project: [NEXT_Retail_RFM_Portfolio.pdf](documentation/NEXT_Retail_RFM_Portfolio.pdf).

---

## What the data says

**A small group carries the business.** 1,265 Champions are about a fifth of the customers (21.5%) and bring in 11.77M of the 17.37M in revenue, which is 67.7%. If I had to protect one thing, it would be this group.

**Half the customer base has gone quiet.** 50.84% haven't ordered in 90 days. At Risk and Lost together are 40% of all customers, and they still account for roughly 2.25M in past revenue.

**Some churned customers are hiding in plain sight.** About 640 customers who haven't ordered in 90 days sit inside Loyal and Needs Attention, so they never show up on an At Risk or Lost list. It is easy to miss them.

**The UK is almost everything.** 5,351 of the 5,879 customers and 82.8% of revenue.

**EIRE and the Netherlands stand out.** EIRE has only 4 customers but 616K in revenue, so those are a handful of very valuable accounts. The Netherlands has 22 customers, over half a million in revenue and a 72.7% churn rate.

### Results by segment

| Segment | Customers | % of customers | Revenue | % of revenue | Churned |
|---|---:|---:|---:|---:|---:|
| Champions | 1,265 | 21.52% | 11,765,378 | 67.72% | 0% |
| Loyal | 1,338 | 22.76% | 2,716,443 | 15.63% | 31.09% |
| At Risk | 708 | 12.04% | 1,521,050 | 8.75% | 100% |
| Lost | 1,644 | 27.96% | 725,082 | 4.17% | 100% |
| Needs Attention | 686 | 11.67% | 566,120 | 3.26% | 32.22% |
| New | 238 | 4.05% | 80,505 | 0.46% | 0% |
| **Total** | **5,879** | | **17,374,578** | | **50.84%** |

### Results by country

| Country | Customers | Revenue | Churned |
|---|---:|---:|---:|
| United Kingdom | 5,351 | 14,389,210 | 51.15% |
| EIRE | 4 | 616,369 | 50.00% |
| Netherlands | 22 | 554,038 | 72.73% |
| Germany | 107 | 425,940 | 35.51% |
| France | 93 | 347,091 | 35.48% |
| Australia | 13 | 158,776 | 61.54% |
| Spain | 41 | 120,362 | 43.90% |

---

## What I would do about it

- **Champions:** look after them first. Early access to new products, loyalty perks, a thank-you gift, and a named contact for the biggest accounts. Losing a few of them costs more than losing hundreds of Lost customers.
- **Loyal:** keep them buying with bundles and repeat-order offers, and nudge them toward Champion. Start with the roughly 416 who have already gone quiet.
- **At Risk:** this is the best win-back group. They used to buy often. Send personal offers soon, before they drift into Lost.
- **Lost:** try one low-cost "we miss you" campaign. If they don't respond, stop spending on them.
- **Needs Attention:** they buy recently but not often, and about 32% have already gone quiet. Offer product suggestions that help them place a second and third order.
- **New:** a welcome message and a small gift. The second order is where a one-time buyer becomes a regular.
- **Markets:** protect the EIRE accounts, and find out why Dutch customers leave so often. Only after that would I test whether similar buyers exist in those markets.

---

## The dashboard

Three pages: a home page with navigation, a **Revenue & Customers Overview**, and a **Customer RFM & Country Analysis** page. Each report page has slicers for month, quarter, year, country, segment and churn status, plus a toggle (Revenue / Customers on the first, Segment / Country on the second).

| Revenue | Customers |
|---|---|
| ![Revenue overview](Dashboards%20Screenshots/Revenue%20Overview.png) | ![Customers overview](Dashboards%20Screenshots/Customers%20Overview.png) |

| Segments | Countries |
|---|---|
| ![Segment analysis](Dashboards%20Screenshots/Customer%20RFM%20Segment%20Analysis.png) | ![Country analysis](Dashboards%20Screenshots/Country%20Analysis.png) |

---

## How it was built

**Data.** Online Retail II from the UCI Machine Learning Repository (donated by Daqing Chen): 1,067,371 transaction lines from December 2009 to December 2011, with invoice, product, quantity, price, customer ID and country.

**Cleaning (SQL).** I joined the two yearly tables, then removed exact duplicates, rows without a customer ID (I can't score a customer I can't identify), zero or negative quantities (returns and cancellations) and test products. I also trimmed the product descriptions and converted the invoice date from text to a timestamp. I checked row counts after each step. The analysis table ends up with 779,483 rows.

**RFM scoring.** For each customer:

- **Recency:** days since their last order, counted from 10 December 2011 (the day after the last transaction in the data)
- **Frequency:** number of distinct invoices
- **Monetary:** total spend (`quantity x price`)

Each is scored from 1 to 5. Recency and Monetary use quintiles (`NTILE(5)`). Frequency uses fixed bands: 1 order, 2 orders, 3 to 4, 5 to 9, and 10 or more.

**Segments:**

| Segment | Rule |
|---|---|
| Champions | R >= 4, F >= 4, M >= 4 |
| New | R >= 4, F = 1 |
| At Risk | R <= 2, F >= 3 |
| Lost | R <= 2, F <= 2 |
| Loyal | R >= 3, F >= 3 |
| Needs Attention | everyone else |

**Churn.** A customer is flagged as churned if their last order was more than 90 days before the reference date. It is a simple fixed rule, agreed in the [BRD](documentation/NEXT%20Gifting%20BRD.docx), not a statistically derived cut-off.

**A change I made along the way.** My first version scored frequency with `NTILE` too. Thousands of customers have exactly one order, and `NTILE` splits identical values across different groups, so two customers with the same behaviour could get different scores. Switching frequency to fixed bands fixed that, and the numbers above come from the corrected version.

---

## Things to keep in mind

- **Churn and segments are linked.** Both depend on recency, so At Risk and Lost are 100% churned and Champions 0% by construction. The useful numbers are how big each group is, how much revenue it holds, and the churned customers inside Loyal and Needs Attention.
- **The churn trend charts look better than reality.** Churn by month, quarter and year drops toward 2011 because recent customers haven't had time to go quiet yet. It doesn't mean retention improved.
- **Wholesale and retail buyers aren't separated,** because the data doesn't tell them apart. A few large accounts, like the ones in EIRE, can dominate a country's numbers.
- **Some non-product lines** (such as manual adjustments) may still be inside revenue, and zero-price rows were reviewed but kept.
- **It is history only.** No promotions, seasonality or forecasting, and it is segmentation, not a predictive churn model.

**If I kept going:** split wholesale from retail, add a revenue-at-risk view, add customer lifetime value, and try a predictive churn model.

---

## Repository

```
├── Dashboards Screenshots/     dashboard images used in this README
├── NEXT Gifting Dataset/       raw data, plus the cleaned data and RFM output
├── Power bi dashboard/         NEXT Retail Gifting.pbix
├── SQL/                        SQL cleaning and analytics.sql
├── documentation/              business requirements document and project PDF
└── README.md
```

## Run it yourself

1. Unzip `NEXT Gifting Dataset.zip` from the `NEXT Gifting Dataset` folder.
2. Create a PostgreSQL database and load the two yearly files into `next_1` and `next_2`.
3. Run [`SQL cleaning and analytics.sql`](SQL/SQL%20cleaning%20and%20analytics.sql) from top to bottom.
4. Open the [`.pbix`](Power%20bi%20dashboard/NEXT%20Retail%20Gifting.pbix) in Power BI, point it at your database and refresh.

Want to skip the SQL? `Clean Data & RFM segmentation.zip` has the cleaned data and the final customer segments.

---

## About me

I'm Sami Ullah, a data analyst working with SQL and Power BI. I like projects that start with a messy table and end with a decision someone can actually make. If you have customer data and would like something similar, get in touch through [GitHub](https://github.com/SamiUllah568).
