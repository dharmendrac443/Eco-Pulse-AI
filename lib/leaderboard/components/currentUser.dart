import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';

Widget buildCurrentUserRow(Map<String, dynamic> player) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blueAccent, // Change color as needed
          shape: BoxShape.circle,
        ),
        child: Text(
          '${player['rank']}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      Row(
        children: [
          Flexible(
            child: Text(
              player['name'],
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: 8),
          CountryFlag.fromCountryCode(
            player['countrycode'],
            width: 16,
            height: 12,
          ),
        ],
      ),
      Container(
        padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.greenAccent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '${player['score'].toInt()}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
    ],
  );
}
