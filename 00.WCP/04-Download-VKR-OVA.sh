#!/bin/bash
 
# 设置基础路径和 URL
base_depot_location="/Downloads/vcfdepot/tanzu"
base_tkg_content_library_uri="https://wp-content.vmware.com/v2/latest"
tkg_content_library_lib_url="$base_tkg_content_library_uri/lib.json"
tkg_content_library_items_url="$base_tkg_content_library_uri/items.json"
 
# 创建基础目录（如果不存在）
mkdir -p "$base_depot_location"
 
echo "Downloading lib.json"
curl -L -o "$base_depot_location/lib.json" "$tkg_content_library_lib_url"
 
echo "Downloading items.json"
curl -L -o "$base_depot_location/items.json" "$tkg_content_library_items_url"
 
# 读取 items.json 内容
items=$(cat "$base_depot_location/items.json")
 
# 遍历每个 item
echo "$items" | jq -c '.items[]' | while read -r allitems; do
    dirname=$(echo "$allitems" | jq -r '.name')
    downloadurls=$(echo "$allitems" | jq -r '.files[].hrefs')
 
    newdir="$base_depot_location/$dirname"
    mkdir -p "$newdir"
 
    echo "Downloading files for: $dirname"
 
    echo "$downloadurls" | jq -c '.[]' | xargs -I % wget --no-if-modified-since -N -P "$newdir/" "$base_tkg_content_library_uri/%"
 
done
