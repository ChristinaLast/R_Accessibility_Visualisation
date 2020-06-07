library(dplyr)

allgeojson <- geojsonio::geojson_read("data/LA_County.geojson", what = "sp")


allgeojson_unique = allgeojson[!duplicated(allgeojson$COMMNAME), ]
row.names(allgeojson_unique) <- allgeojson_unique$COMMNAME


allgeojson_unique$City_name = as.character(allgeojson_unique$COMMNAME)
allgeojson_unique$Total_Accessibility_20_seg = as.character(allgeojson_unique$Tot_r_20_seg)
allgeojson_unique$HH_Trans_cost_perc_income_seg = as.character(allgeojson_unique$ht_ami_seg)
allgeojson_unique$Score = as.numeric(allgeojson_unique$Tot_r_20)
allgeojson_unique$Tot_r_20 = as.numeric(allgeojson_unique$Tot_r_20)

allgeojson_unique$pct_transi = as.numeric(allgeojson_unique$pct_transi)

allgeojson_unique$percentage_transit = allgeojson_unique$pct_transi

cleantable <- allgeojson_unique

cleantable$City_name = as.character(cleantable$City_name)
cleantable$Total_Accessibility_20_seg = as.character(cleantable$Total_Accessibility_20_seg)
cleantable$HH_Trans_cost_perc_income_seg = as.character(cleantable$HH_Trans_cost_perc_income_seg)
