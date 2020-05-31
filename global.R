library(dplyr)

allcity <- read.csv("data/all_data_city.csv")



allcity_unique = allcity[!duplicated(allcity$COMMNAME), ]
row.names(allcity_unique) <- allcity_unique$COMMNAME


allcity_unique$City_name = as.character(allcity_unique$COMMNAME)
allcity_unique$Total_Accessibility_20_seg = as.character(allcity_unique$Tot_r_20_seg)
allcity_unique$HH_Trans_cost_perc_income_seg = as.character(allcity_unique$ht_ami_seg)
allcity_unique$Score = as.numeric(allcity_unique$Tot_r_20)
allcity_unique$Tot_r_20 = as.numeric(allcity_unique$Tot_r_20)

allcity_unique$pct_transi = as.numeric(allcity_unique$pct_transi)

allcity_unique$percentage_transit = allcity_unique$pct_transi

cleantable <- allcity_unique %>%
  select(
    City_name = City_name,
    Score = Score,
    County = kind,
    Total_Accessibility_20_mins = Tot_r_20,
    population = population,
    percentage_transit = pct_transi,
    Black_Afri = Black_Afri,
    Hispanic = Hispanic,
    White_Alon = White_Alon,
    Total_Accessibility_20_seg = Tot_r_20_seg,
    HH_Trans_cost = ht_ami,
    HH_Trans_cost_perc_income_seg = ht_ami_seg,
    Lat = latitude,
    Long = longitude,
    location = location
  )

cleantable$City_name = as.character(cleantable$City_name)
cleantable$Total_Accessibility_20_seg = as.character(cleantable$Total_Accessibility_20_seg)
cleantable$HH_Trans_cost_perc_income_seg = as.character(cleantable$HH_Trans_cost_perc_income_seg)
