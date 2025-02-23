// ignore: file_names
import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'ShiningStar.dart';

userCard(player, isCurrentUser) {
  return Card(
    color: Colors.white,
    elevation: 2,
    child: Container(
      decoration: isCurrentUser
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(
                colors: [
                  Colors.green[300]!,
                  Colors.green[700]!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        child: Table(
          columnWidths: const {
            0: FixedColumnWidth(70.0), // Adjust the width as needed
            1: FlexColumnWidth(),
            2: FixedColumnWidth(50.0), // Adjust the width as needed
          },
          children: [
            TableRow(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (player['rank'] == 1)
                      ShiningStar(
                        gradientColors: [
                          Colors.amber[300]!,
                          Colors.amber[700]!,
                        ],
                      )
                    else if (player['rank'] == 2)
                      ShiningStar(
                        gradientColors: [
                          Colors.grey[300]!,
                          Colors.grey[700]!,
                        ],
                      )
                    else if (player['rank'] == 3)
                      ShiningStar(
                        gradientColors: [
                          Colors.brown[300]!,
                          Colors.brown[700]!,
                        ],
                      )
                    else
                      Text(
                        '${player['rank']}',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Flexible(
                      child: Text(
                        player['name'],
                        style: TextStyle(fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 10),
                    CountryFlag.fromCountryCode(
                      player['countrycode'],
                      width: 16,
                      height: 10,
                    ),
                  ],
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Text(
                        '${player['score'].toInt()}',
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
