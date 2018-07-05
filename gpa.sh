#!/bin/bash

if [ -z "$1" -o -z "$2" ]; then
	echo "使用方法: gpa.sh <username> <password>"
	exit 1
fi

function scoreToGrade() {
	if [ $1 -ge 97 ]; then
		echo 4.00
	elif [ $1 -ge 93 ]; then
		echo 3.94
	elif [ $1 -ge 90 ]; then
		echo 3.85
	elif [ $1 -ge 87 ]; then
		echo 3.73
	elif [ $1 -ge 83 ]; then
		echo 3.55
	elif [ $1 -ge 80 ]; then
		echo 3.32
	elif [ $1 -ge 77 ]; then
		echo 3.09
	elif [ $1 -ge 73 ]; then
		echo 2.78
	elif [ $1 -ge 70 ]; then
		echo 2.42
	elif [ $1 -ge 67 ]; then
		echo 2.08
	elif [ $1 -ge 63 ]; then
		echo 1.63
	elif [ $1 -ge 60 ]; then
		echo 1.15
	else
		echo 0
	fi
}

loginurl="https://cas.sustc.edu.cn/cas/login"
scoreurl="http://jwxt.sustc.edu.cn/jsxsd/kscj/cjcx_list"

rm -f /tmp/cascookie
execution=$(curl --silent --cookie-jar /tmp/cascookies -L "$scoreurl" | grep -P -o '(?<=name="execution" value=").*(?="/><input type="hidden" name="_eventId)')
cas_code=$(curl --silent --write-out %{http_code} --output /dev/null --cookie /tmp/cascookies --cookie-jar /tmp/cascookies -H "Content-Type: application/x-www-form-urlencoded" -L -X POST "$loginurl" --data "username=$1&password=$2&_eventId=submit&execution=$execution&geolocation=")

if [ $cas_code -ne 200 ]; then
	echo "登录失败, 返回代码: $cas_code"
	exit 1
fi

ORIGINAL_IFS="$IFS"
IFS="</td>"
result=($(curl --silent --cookie /tmp/cascookies --cookie-jar /tmp/cascookies -L "$scoreurl"))
IFS="$ORIGINAL_IFS"

grades=0
credits=0

for each in ${result[*]:750}
do
	if [ -z "$last_score" ]; then
		score=$(echo "$each" | grep -P -o "(?<=&zcj=)\d.*(?=',)")
		if [ -n "$score" ]; then
			last_score="$score"
		fi
	else
		credit=$(echo "$each" | grep -P -o "\d.*")
		if [ -n "$credit" ]; then
			grades=$(echo "$grades+$credit*$(scoreToGrade $last_score)" | bc)
			credits=$(echo "$credits+$credit" | bc)
			last_score=""
		fi
	fi
done

GPA=$(echo "scale=2; $grades/$credits" | bc)
echo "你的 GPA 是: $GPA"
