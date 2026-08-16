1. LOAD YOUR DATASET
* Replace 'your_gold_file.csv' with your actual filename if different
import delimited "your_gold_file.csv", clear 

* 2. PARSE THE DATE AND INITIALIZE INDEX
generate stata_date = mdy(Month, Day, Year)
format stata_date %td
generate time_index = _n
tsset time_index

* 3. FEATURE ENGINEERING & TRANSFORMATION
generate ln_price = log(close)
generate log_return = d.ln_price

* 4. EXPORT CHART 1: PRICE VS. 365-DAY MOVING AVERAGE
twoway (line close stata_date, lcolor(navy) lwidth(medium)) ///
       (line ma_365 stata_date, lcolor(orange) lwidth(small) lpattern(dash)), ///
    title("Gold Price & 365-Day Moving Average (2002-2026)", size(medium)) ///
    subtitle("Visualizing structural macro trends over 24 years", size(small)) ///
    xtitle("Year") ytitle("Price (USD)") ///
    legend(order(1 "Closing Price" 2 "365-Day MA")) ///
    graphregion(color(white)) bgcolor(white)
graph export "gold_trends_ma.png", replace

* 5. EXPORT CHART 2: DAILY LOG RETURNS
twoway (line log_return stata_date, lcolor(teal) lwidth(vthin)), ///
    title("Daily Log Returns: Variance Stabilization", size(medium)) ///
    subtitle("Transforming non-stationary prices into stationary metrics", size(small)) ///
    xtitle("Year") ytitle("Log Return %") ///
    graphregion(color(white)) bgcolor(white)
graph export "gold_log_returns.png", replace

* 6. TIME SERIES MODEL ESTIMATION
arima ln_price, arima(1,1,1) vce(robust)

* 7. 30-DAY OUT-OF-SAMPLE DYNAMIC FORECAST PIPELINE
drop if missing(close)
scalar last_obs = _N
capture drop ln_forecast
capture drop price_forecast

tsappend, add(30)
predict ln_forecast, y dynamic(last_obs + 1)
generate price_forecast = exp(ln_forecast)

* 8. EXPORT CHART 3: FORECASTED PLOT
twoway (line price_forecast time_index if missing(close), lcolor(blue) lwidth(medium)), ///
    title("Gold Price 30-Day Dynamic Forecast", size(medium)) ///
    subtitle("Integrated ARIMA(1,1,1) model projections", size(small)) ///
    xtitle("Time Index (Days)") ytitle("Predicted Price (USD/oz)") ///
    graphregion(color(white)) bgcolor(white)
graph export "gold_forecast_output.png", replace

* 9. PRINT THE RESULTS TO THE TERMINAL WINDOW
list time_index price_forecast if missing(close) in -30/L