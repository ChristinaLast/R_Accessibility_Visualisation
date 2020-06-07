# -*- coding: utf-8 -*-
import pandas as pd
import numpy as np
import isort



from shapely import wkt
from shapely.geometry import MultiPolygon, shape
import geopandas as gpd



pd.set_option('display.max_columns', None)
data_path = './data/'

def get_accessibility_segment(Tot_r_20):
    if Tot_r_20 <= 200000:
        return '200000-'
    elif Tot_r_20 <= 350000:
        return '200000-350000'
    elif Tot_r_20 <= 500000:
        return '350000-500000'
    elif Tot_r_20 <= 650000:
        return '500000-650000'
    elif Tot_r_20 <= 750000:
        return '650000-750000'
    else:
        return '750000+'

def get_ht_ami_segment(ht_ami):
    if ht_ami <= 45:
        return '45%-'
    elif ht_ami <= 55:
        return '45%-55%'
    elif ht_ami <= 65:
        return '55%-65%'
    elif ht_ami <= 75:
        return '65%-75%'
    elif ht_ami <= 85:
        return '75%-85%'
    else:
        return '85%+'

def get_geometry(geo_json, data_json):
    for geo in range(len(geo_json['features'])):
        for name in range(len(data_json)):
            if geo_json['features'][geo]['properties']['name'] == data_json[name]['COMMNAME']:
                data_json[name].update(geo_json['features'][geo]) #change update function
                del data_json[name]['properties'] #change update function

    return data_json



def get_data():
    # Getting data from raw csv
    all_data_block = pd.read_csv(data_path + 'Spatial_weights_pred.csv')
    # Getting spatial data for LA cities
    all_lat_lon = pd.read_csv(data_path + 'la_neighborhoods.csv')

    all_lat_lon['the_geom'] = all_lat_lon['the_geom'].apply(wkt.loads)
    all_lat_lon = gpd.GeoDataFrame(all_lat_lon, geometry="the_geom")

    # Dropping unnecessary columns
    all_data_city = all_data_block.drop(['Unnamed: 0','CB10','OBJECTID_1','GEOID10','CTCB10','BG10','X_CENTER','Y_CENTER','Shape_Leng','Shape_Area','BlockId','BlockgroupId','TractId'], axis=1)
    #Groupby LA cities and mean numerican values
    all_data_city_mean = all_data_city.groupby('COMMNAME').mean().reset_index().drop(['Black_Afri','Hispanic','White_Alon'],axis=1)
    #total sum of ethnicity at the city level
    all_data_ethnicity = all_data_city[['COMMNAME', 'Black_Afri','Hispanic','White_Alon']]
    all_data_ethnicity_sum = all_data_ethnicity.groupby('COMMNAME').sum().reset_index()
    #merging averaged and totalled dataframes on LA city
    all_data_city = all_data_city_mean.merge(all_data_ethnicity_sum, on='COMMNAME')
    all_data_city = all_data_city.reset_index(drop=True)
    # Reformatting LA city name
    all_data_city['COMMNAME'] = all_data_city['COMMNAME'].map(lambda x: x.lstrip('City of '))
    all_data_city['COMMNAME'] = all_data_city['COMMNAME'].map(lambda x: x.lstrip('Unincorporated - '))
    #selecting subset of columns
    all_data_city = all_data_city[['COMMNAME','Tot_r_10','Tot_r_20','Tot_r_50','ht_ami', 'population', 'co2_per_hh', 'autos_per_', 'pct_transi', 'res_densit', 'emp_gravit','emp_ndx','h_cost','Black_Afri','Hispanic','White_Alon']]
    #integer conversion
    cols = ['Tot_r_20', 'population', 'pct_transi', 'Black_Afri','Hispanic','White_Alon']
    all_data_city[cols] = all_data_city[cols].applymap(np.int64)
    # creating segmented
    all_data_city['Tot_r_20_seg'] = all_data_city['Tot_r_20'].apply(lambda Tot_r_20: get_accessibility_segment(Tot_r_20))
    all_data_city['ht_ami_seg'] = all_data_city['ht_ami'].apply(lambda ht_ami: get_ht_ami_segment(ht_ami))
    # Merging with the spatial data
    all_data_city = all_data_city.merge(all_lat_lon, left_on='COMMNAME', right_on="name")
    all_data_city.to_csv(data_path+'all_data_city.csv')
    #Creating geojson with spatial data activated as geometry
    all_data_city['the_geom'] = all_data_city['the_geom'].apply(wkt.loads)
    all_data_city_gdf = gpd.GeoDataFrame(LA_county_csv, geometry="the_geom")
    # dropping duplicate cities
    all_data_city_gdf = all_data_city_gdf.drop_duplicates(subset='COMMNAME', keep="first")
    all_data_city_gdf['City_name'] = all_data_city_gdf['COMMNAME']
    all_data_city_gdf.to_file("/Users/admin/R-Accessibility-Vis/data/LA_county.geojson", driver='GeoJSON')
    #with open(data_path + 'geojson/la-county-neighborhoods-v6.geojson') as data_file:
    #    geo_json = json.load(data_file)

    #with open(data_path + 'geojson/data_geo.json', 'w') as data_geo_out:
    #    data_json = get_geometry(geo_json, data_json)
    #    json.dump(data_json, data_geo_out)

    return all_data_city_gdf
