#�������������� � ������� ���������� �������� � SQL Server, ��������� ����� RODBC, � ���������� � ���������
library("RODBC")
dbconnection <- odbcDriverConnect("Driver=ODBC Driver 11 for SQL Server;Server=****; Database=****;Uid=; Pwd=; trusted_connection=yes")
Groupped_Fact_Data_44FZ_by_month<- sqlQuery(dbconnection,paste("select CalendarYear,monthnumber,sum(procedure_count) as procedure_count from [bi2].[BI_Analytics].[dbo].[Forecasting_44FZ_Fact]  group by CalendarYear,monthnumber order by CalendarYear,monthnumber;"))
#���������� ��������� ����������� ������

library(lubridate)
library(xts)
library(plm)
library(forecast)
library(corrplot)
library(zoo)

#� ������ ������� ���������� ��������� �������� ������ ������

#���������� ��������� ����������� ������ ��� �������� � ������������ ������ � ������ TimeSeries
TS_data <- ts(Groupped_Fact_Data_44FZ_by_month$procedure_count,start = c(2014,1), end = c(2018,10),frequency = 12)

#������� ������������, ���� ������, ��� �� ���� �������������� ��� ��������� ��� � ����� �������� �����
plot(decompose(TS_data))

#���������� ������������� ������� - 4 ������ ����
ts_training_set <- window(TS_data,start=c(2014,1),end=c(2017,12))

#������� ������ ������
auto_arima <- auto.arima(ts_training_set) #���������� ARIMA ������
neural_net1 <- nnetar(ts_training_set,lambda=0) #��������� ���� � ������=0 (��� �������������� ��������)
neural_net2 <- nnetar(ts_training_set,lambda=1) #��������� ���� � ������=0 (��� �������������� ��������)
HW_Fit_add <- hw(ts_training_set,seasonal="additive") #������� �� ������ ����������������� �����������  ������ - �������� � ���������� �����������
HW_Fit_multi <- hw(ts_training_set,seasonal="multiplicative") #������� �� ������ ����������������� �����������  ������ - �������� � ����������������� �����������

#�������� ������� � ������� ��������� � ������ 10 ������� 2018 ����

autoplot(ts_p)+
  autolayer(forecast(neural_net1,h=10),series = "NeuralNet1",PI=FALSE) +
  autolayer(forecast(neural_net2,h=10),series = "NeuralNet2",PI=FALSE) +
  autolayer(forecast(HW_Fit_add,h=10),series = "HW_Fit_add",PI=FALSE) +
  autolayer(forecast(HW_Fit_multi,h=10),series = "HW_Fit_multi",PI=FALSE) +
  autolayer(window(TS_data,start=c(2018,1),end=c(2018,10)),series = "Fact")  #���� 10 ������� - test_set

#���������, ��������, ����� ����� �������� ���� ������ ������-��������: "�������" ����� � ����������. 
#����� ����� ���������� ��������� ������, ������� summary, ���� ������� �������� ������ (AIC)

summary(HW_Fit_add) #AIC 1157   
summary(HW_Fit_multi) #AIC 1241 
#�������� ������ ����������������� ����������� � ������� � ����������� ������ - �������� � ���������� �����������!

#####################################################################

#������ ���������� � ������ ��������: �������� �������� �� 2 ������ 2018�� � �� ���� 2019 ���

#�������������� ����� ������ bottom-up(�����-�����), 
#�.�. �������� ����������� �����������, ���������� ��������� ����������� �� ���������� (�������� ���� ������� � ������� ������ ��������� ������ �������).
#�������� ������ ������ �� �������� �����������, �� ��� ��������� �������, ����� ������� �� �����-���������� � ����� ������� �������, ������������� �� �������� ���������� �������
#�������� �� ���� �� ��� ������

#�������� ��������, ��� ������ ����� � �������� - ����� ���������, ������ - ��� ��� ���
train_data_1_0 <- sqlQuery(dbconnection,paste("select sum(Procedure_Count) as  Procedure_Count from [bi2].[BI_Analytics].[dbo].[Forecasting_44FZ_Fact_for_modeling] where DocPublishDate<='20181031' and Sum_range_Order=1 and IS_MSP_Purchase=0 group by year(DocPublishDate),MonthNumber order by year(DocPublishDate),MonthNumber;"))
train_data_2_0 <- sqlQuery(dbconnection,paste("select sum(Procedure_Count) as  Procedure_Count from [bi2].[BI_Analytics].[dbo].[Forecasting_44FZ_Fact_for_modeling] where DocPublishDate<='20181031' and Sum_range_Order=2 and IS_MSP_Purchase=0 group by year(DocPublishDate),MonthNumber order by year(DocPublishDate),MonthNumber;"))
train_data_3_0 <- sqlQuery(dbconnection,paste("select sum(Procedure_Count) as  Procedure_Count from [bi2].[BI_Analytics].[dbo].[Forecasting_44FZ_Fact_for_modeling] where DocPublishDate<='20181031' and Sum_range_Order=3 and IS_MSP_Purchase=0 group by year(DocPublishDate),MonthNumber order by year(DocPublishDate),MonthNumber;"))
train_data_1_1 <- sqlQuery(dbconnection,paste("select sum(Procedure_Count) as  Procedure_Count from [bi2].[BI_Analytics].[dbo].[Forecasting_44FZ_Fact_for_modeling] where DocPublishDate<='20181031' and Sum_range_Order=1 and IS_MSP_Purchase=1 group by year(DocPublishDate),MonthNumber order by year(DocPublishDate),MonthNumber;"))
train_data_2_1 <- sqlQuery(dbconnection,paste("select sum(Procedure_Count) as  Procedure_Count from [bi2].[BI_Analytics].[dbo].[Forecasting_44FZ_Fact_for_modeling] where DocPublishDate<='20181031' and Sum_range_Order=2 and IS_MSP_Purchase=1 group by year(DocPublishDate),MonthNumber order by year(DocPublishDate),MonthNumber;"))
train_data_3_1 <- sqlQuery(dbconnection,paste("select sum(Procedure_Count) as  Procedure_Count from [bi2].[BI_Analytics].[dbo].[Forecasting_44FZ_Fact_for_modeling] where DocPublishDate<='20181031' and Sum_range_Order=3 and IS_MSP_Purchase=1 group by year(DocPublishDate),MonthNumber order by year(DocPublishDate),MonthNumber;"))
#������� ������������� ��������� ���� �� ����-�����
ts_1_0 <- zooreg(train_data_1_0,start = as.yearmon("2014-01"),end = as.yearmon("2018-10"),freq=12)
ts_2_0 <- zooreg(train_data_2_0,start = as.yearmon("2014-01"),end = as.yearmon("2018-10"),freq=12)
ts_3_0 <- zooreg(train_data_3_0,start = as.yearmon("2014-01"),end = as.yearmon("2018-10"),freq=12)
ts_1_1 <- zooreg(train_data_1_1,start = as.yearmon("2014-01"),end = as.yearmon("2018-10"),freq=12)
ts_2_1 <- zooreg(train_data_2_1,start = as.yearmon("2014-01"),end = as.yearmon("2018-10"),freq=12)
ts_3_1 <- zooreg(train_data_3_1,start = as.yearmon("2014-01"),end = as.yearmon("2018-10"),freq=12)
#"�����������"  ��� ���� ������� - �������
HW_Fit_1_0 <- hw(ts_1_0,seasonal="additive")
HW_Fit_2_0 <- hw(ts_2_0,seasonal="additive")
HW_Fit_3_0 <- hw(ts_3_0,seasonal="additive")
HW_Fit_1_1 <- hw(ts_1_1,seasonal="additive")   
HW_Fit_2_1 <- hw(ts_2_1,seasonal="additive") 
HW_Fit_3_1 <- hw(ts_3_1,seasonal="additive") 
#������������
prognoz_1_0<-forecast(HW_Fit_1_0,h=14) 
prognoz_2_0<-forecast(HW_Fit_2_0,h=14)
prognoz_3_0<-forecast(HW_Fit_3_0,h=14)
prognoz_1_1<-forecast(HW_Fit_1_1,h=14)
prognoz_2_1<-forecast(HW_Fit_2_1,h=14) 
prognoz_3_1<-forecast(HW_Fit_3_1,h=14)
#�������� ���������� � ������ ��� ���������� ���������
Forecast_2019_Count<-data.frame(prognoz_1_0$mean,prognoz_2_0$mean,prognoz_3_0$mean,prognoz_1_1$mean,prognoz_2_1$mean,prognoz_3_1$mean)
write.xlsx(Forecast_2019_Count, "Forecast_2019_Count.xlsx", col_names = TRUE)