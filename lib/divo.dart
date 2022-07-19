import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Divo extends StatefulWidget {
  const Divo({Key? key}) : super(key: key);

  @override
  _DivoState createState() => _DivoState();
}

class _DivoState extends State<Divo> {
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  Color brightGreen = Color(0xffC2F63C);
  Color darkBrightGreen = Color(0xff01CB06);
  Color white = Colors.white;
  Color black = Colors.black;

  String api = "https://vast-refuge-05196.herokuapp.com/";
  //String api = "http://10.0.0.4:5000/";

  bool loadedData = false;

  List<String> stocks = [];
  List<double> amounts = [];

  List<double> monthlyDivsPerShare = [];
  List<double> divRatePerShare = [];
  List<double> price = [];

  var appbarspacing = 6.0;

  var assetValue = 0.0;
  String avgAPY = "";
  var monthlyDiv = 0.0;
  var yearlyDiv = 0.0;

  final symbolController = TextEditingController();
  final amountController = TextEditingController();

  final editSymbolControllers = [];
  final editAmountControllers = [];

  List<Widget> cards = [];
  List<Widget> stockcards = [];

  List<bool> loaded = [];

  var first = true;

  Future<bool> getAllData() async {
    
    loadedData = false;
    divRatePerShare = [];
    monthlyDivsPerShare = [];
    price = [];

    for (int i = 0; i < stocks.length; i++) {
      loaded.add(false);
      divRatePerShare.add(0);
      monthlyDivsPerShare.add(0);
      price.add(0);
    }

    buildAllStockCards();
    setUpCards();

    for (int i = 0; i < stocks.length; i++) {
      await getData(i);
      setState(() {
        buildAllStockCards();
        setUpCards();
      });
    }
    loadedData = true;
    return true;
  }

  Future<bool> getData(int i) async {
    String symbol = stocks[i];
    print('getting data');
    final divCurrent =
        await http.get(Uri.parse(api + '/current_div?stock=$symbol'));
    final divMonth =
        await http.get(Uri.parse(api + '/div_rate_monthly?stock=$symbol'));
    final priceRequest = await http.get(Uri.parse(api + '/open?stock=$symbol'));

    double divPerShare = 0.0;
    double divPerMonth = 0.0;
    double stockPrice = 0.0;

    //TODO catch no internet error. Will mess up the loading of anything
    if (divCurrent.statusCode == 200) {
      divPerShare = double.parse(divCurrent.body);
    }
    if (divMonth.statusCode == 200) {
      divPerMonth = double.parse(divMonth.body);
    } else if (divPerShare != 0.0) {
      divPerMonth = divPerShare * (1 / 3);
      print(divPerMonth);
    }
    if (priceRequest.statusCode == 200) {
      stockPrice = double.parse(priceRequest.body);
    }
    print('got data');

    divRatePerShare[i] = (divPerShare);
    monthlyDivsPerShare[i] = (divPerMonth);
    price[i] = (stockPrice);
    loaded[i] = true;
    return true;
  }

  Widget getAppBar() {
    return PreferredSize(
      preferredSize: Size(double.infinity, 300),
      child: Container(
        margin: EdgeInsets.all(0),
        height: 300,
        width: 440,
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: Image.asset(
                "lib/assets/appbar.png",
                width: 400,
                fit: BoxFit.fill,
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                child: Column(
                  children: [
                    Text(
                      "Divo",
                      style: GoogleFonts.rubik(
                        fontWeight: FontWeight.bold,
                        color: brightGreen,
                        fontSize: 35,
                      ),
                    ),
                    SizedBox(
                      height: appbarspacing,
                    ),
                    //#616F39
                    AutoSizeText(
                      "The Monthly Dividend Calculator",
                      maxLines: 1,
                      style: GoogleFonts.lato(
                        color: white,
                        fontSize: 25,
                      ),
                    ),
                    SizedBox(
                      height: appbarspacing,
                    ),
                    RichText(
                      text: TextSpan(
                          text: "\$$assetValue",
                          style: GoogleFonts.lato(
                            color: brightGreen,
                            fontSize: 20,
                          ),
                          children: [
                            TextSpan(
                              text: " current asset value",
                              style: GoogleFonts.lato(
                                color: white,
                                fontSize: 20,
                              ),
                            )
                          ]),
                    ),
                    SizedBox(
                      height: appbarspacing,
                    ),
                    RichText(
                      text: TextSpan(
                          text: "$avgAPY",
                          style: GoogleFonts.lato(
                            color: brightGreen,
                            fontSize: 20,
                          ),
                          children: [
                            TextSpan(
                              text: " avg APY",
                              style: GoogleFonts.lato(
                                color: white,
                                fontSize: 20,
                              ),
                            )
                          ]),
                    ),
                    SizedBox(
                      height: appbarspacing,
                    ),
                    Text(
                      "\$$monthlyDiv/mo",
                      style: GoogleFonts.rubik(
                        fontWeight: FontWeight.bold,
                        color: brightGreen,
                        fontSize: 30,
                      ),
                    ),
                    SizedBox(
                      height: appbarspacing,
                    ),
                    Text(
                      "\$$yearlyDiv/yr",
                      style: GoogleFonts.lato(
                        color: brightGreen,
                        fontSize: 20,
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildStockTile(int i) {
    var symbol = stocks[i].toUpperCase(); //Sets the stock's symbol to all upper case

    double divPerMonthTotal = amounts[i] * monthlyDivsPerShare[i]; //Calculate the total monthly dividend
    divPerMonthTotal = double.parse(divPerMonthTotal.toStringAsFixed(2)); //Rounds to two digits after the decimal.

    double divPerShare = divRatePerShare[i];
    divPerShare = double.parse(divPerShare.toStringAsFixed(2));

    double divPerMonth = monthlyDivsPerShare[i];
    divPerMonth = double.parse(divPerMonth.toStringAsFixed(2));

    double amount = amounts[i];
    amount = double.parse(amount.toStringAsFixed(2));

    editAmountControllers.add(new TextEditingController());
    editSymbolControllers.add(new TextEditingController());

    return stockTile(symbol, divPerShare.toString(), amount.toString(),
        divPerMonthTotal.toString(), i);
  }

  Widget buildLoadingStockTile(int i) {
    var symbol = stocks[i].toUpperCase();

    double amount = amounts[i];
    amount = double.parse(amount.toStringAsFixed(2));

    editAmountControllers.add(new TextEditingController());
    editSymbolControllers.add(new TextEditingController());
    return stockTile(symbol, "Loading...", amount.toString(), "Loading...", i);
  }

  Widget stockTile(String symbol, String divPerShare, String amount, String divPerMonthTotal, int i) {

    var stockPrice = price[i];

    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        color: black,
        border: Border.all(
          width: 5,
          color: darkBrightGreen,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "$symbol",
            style: GoogleFonts.lato(
                color: brightGreen, fontSize: 25, fontWeight: FontWeight.bold),
          ),
          AutoSizeText(
            "\$$stockPrice/share",
            maxLines: 1,
            style: GoogleFonts.lato(color: white),
          ),
          Text(
            "$amount shares",
            style: GoogleFonts.lato(color: white),
          ),
          AutoSizeText(
            "\$$divPerMonthTotal/mo",
            maxLines: 1,
            style: GoogleFonts.rubik(
              color: brightGreen,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          SizedBox(
            width: 30,
            height: 30,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(Icons.edit),
              color: white,
              onPressed: () {
                editSymbolControllers[i].text = stocks[i].toUpperCase();
                editAmountControllers[i].text = amounts[i].toString();
                Alert(
                  context: context,
                  title: "Edit Stock",
                  desc: "Change the info below.",
                  style: AlertStyle(
                    backgroundColor: black,
                    descStyle: GoogleFonts.lato(
                      color: white,
                      fontSize: 25,
                    ),
                    titleStyle: GoogleFonts.lato(
                      color: white,
                      fontSize: 35,
                    ),
                    alertBorder: Border.all(
                      color: darkBrightGreen,
                      width: 5,
                    ),
                  ),
                  content: Container(
                    child: Column(
                      children: [
                        TextField(
                          style: GoogleFonts.lato(
                            color: white,
                            fontSize: 25,
                          ),
                          decoration: InputDecoration(
                            labelText: "Symbol",
                            labelStyle: TextStyle(color: brightGreen),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: darkBrightGreen),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: darkBrightGreen),
                            ),
                            border: UnderlineInputBorder(
                              borderSide: BorderSide(color: darkBrightGreen),
                            ),
                          ),
                          controller: editSymbolControllers[i],
                        ),
                        TextField(
                          style: GoogleFonts.lato(
                            color: white,
                            fontSize: 25,
                          ),
                          decoration: InputDecoration(
                            labelText: "Amount",
                            labelStyle: TextStyle(color: brightGreen),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: darkBrightGreen),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: darkBrightGreen),
                            ),
                            border: UnderlineInputBorder(
                              borderSide: BorderSide(color: darkBrightGreen),
                            ),
                          ),
                          controller: editAmountControllers[i],
                        ),
                      ],
                    ),
                  ),
                  buttons: [
                    DialogButton(
                      color: darkBrightGreen,
                      child: Text(
                        "Edit",
                        style: TextStyle(color: white, fontSize: 20),
                      ),
                      radius: BorderRadius.circular(0.0),
                      onPressed: () {
                        if (editSymbolControllers[i].text != "") {
                          stocks[i] = editSymbolControllers[i].text;
                        }

                        if (editAmountControllers[i].text != "") {
                          amounts[i] =
                              double.parse(editAmountControllers[i].text);
                        }
                        saveData();

                        editSymbolControllers[i].text = "";
                        editAmountControllers[i].text = "";

                        cards = [];
                        stockcards = [];
                        setState(() {
                          buildAllStockCards();
                          setUpCards();
                        });
                        Navigator.pop(context);
                      },
                    ),
                    DialogButton(
                      color: darkBrightGreen,
                      child: Text(
                        "Delete",
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                      onPressed: () {
                        deleteCard(i);

                        setState(() {
                          buildAllStockCards();
                          setUpCards();
                        });

                        Navigator.pop(context);
                      },
                      radius: BorderRadius.circular(0.0),
                    ),
                  ],
                ).show();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget makeSureConnectedToInternetCard() {
    return Container(
        width: 300,
        height: 150,
        decoration: BoxDecoration(
          border: Border.all(
            width: 5,
            color: darkBrightGreen,
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
            bottomLeft: Radius.circular(10),
            bottomRight: Radius.circular(10),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Make Sure",
              style: GoogleFonts.lato(
                  color: brightGreen,
                  fontSize: 25,
                  fontWeight: FontWeight.bold),
            ),
            AutoSizeText(
              "That you are connected to the internet. During this process.",
              maxLines: 2,
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                  color: brightGreen,
                  fontSize: 25,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ));
  }

  Widget addCardCard() {
    return Container(
        width: 300,
        height: 150,
        decoration: BoxDecoration(
          border: Border.all(
            width: 5,
            color: darkBrightGreen,
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
            bottomLeft: Radius.circular(10),
            bottomRight: Radius.circular(10),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "To add a card",
              style: GoogleFonts.lato(
                  color: brightGreen,
                  fontSize: 25,
                  fontWeight: FontWeight.bold),
            ),
            AutoSizeText(
              "Click the + button.",
              maxLines: 2,
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                  color: brightGreen,
                  fontSize: 25,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ));
  }

  Widget verticalSpacerCard() {
    return SizedBox(
      height: 40,
    );
  }

  buildAllStockCards() {
    //Clears the stock cards array
    stockcards = [];

    //Checks to see if the information is loaded for a stock and either adds a stock tile or a loading stock tile.
    for (int i = 0; i < stocks.length; i++) {
      if (loaded[i]) {
        stockcards.add(buildStockTile(i));
      } else {
        stockcards.add(buildLoadingStockTile(i));
      }
    }

    //Formats and adds the cards to the screen.
    setState(() {
      setUpCards();
    });
  }

  setUpCards() {
    //Checks to see if all of the data is loaded/
    bool isLoaded = true;
    for (bool load in loaded) {
      if (!load) {
        isLoaded = false;
      }
    }

    //If all of the data is loaded calculates overall stats
    if (isLoaded) {
      //Calculating monthly and yearly div
      monthlyDiv = 0.0;
      yearlyDiv = 0.0;
      for (int i = 0; i < monthlyDivsPerShare.length; i++) {
        monthlyDiv += (monthlyDivsPerShare[i] * amounts[i]);
        yearlyDiv += (monthlyDivsPerShare[i] * amounts[i]) * 12;
      }
      monthlyDiv = double.parse(monthlyDiv.toStringAsFixed(2));
      yearlyDiv = double.parse(yearlyDiv.toStringAsFixed(2));

      //Calculating the total asset value
      assetValue = 0;
      for (int i = 0; i < amounts.length; i++) {
        assetValue += price[i] * amounts[i];
      }
      assetValue = double.parse(assetValue.toStringAsFixed(2));

      //Calculating the avg APY
      avgAPY = ((yearlyDiv / assetValue) * 100.0).toStringAsFixed(3);
    }

    //Empty existing cards
    cards = [];

    //Add the app bar with updated information
    cards.add(getAppBar());

    //Adds a card that tells the user to make sure they are connected to the internet because the app is loading.
    if (!isLoaded) {
      cards.add(makeSureConnectedToInternetCard());
      cards.add(verticalSpacerCard());
    }

    //Formats the stock cards 2 in a row or one if last and the length of the stockcards is odd.
    for (var i = 0; i < stockcards.length; i++) {
      if (i % 2 == 0 && i + 1 < stockcards.length) {
        cards.add(Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            stockcards[i],
            SizedBox(
              width: 40,
            ),
            stockcards[i + 1]
          ],
        ));
        cards.add(verticalSpacerCard());
        i++;
      } else {
        cards.add(stockcards[i]);
      }
    }

    if (stockcards.length == 0) {
      cards.add(addCardCard());
    }

    //Adds some space on the bottom because of the button on the bottom.
    cards.add(verticalSpacerCard());
    cards.add(verticalSpacerCard());

    //TODO if there is no internet inform the user to connect to the internet.
    //TODO if there are no cards add a message informing the user to click the add button on the bottom of the screen.
    //Updates the screen to add/update the cards.
    setState(() {});
  }

  addCard() async {
    //Saves stocks and amounts
    saveData();

    //Sets i to 1 - stocks.length, the index of the new data entries so the loading card can have the proper stock and amount data.
    int i = stocks.length - 1;

    //Gets the newest entries stock dividend data.
    loaded.add(false);
    divRatePerShare.add(0);
    monthlyDivsPerShare.add(0);
    price.add(0);

    //Refresh screen with new loading card.
    buildAllStockCards();
    setUpCards();

    //Loads in new data and refreshes screen with new card.
    await getData(i);
    buildAllStockCards();
    setState(() {
      setUpCards();
    });
  }

  deleteCard(int i) {
    //Removes all data related to the individual stock.
    stocks.removeAt(i);
    amounts.removeAt(i);
    monthlyDivsPerShare.removeAt(i);
    divRatePerShare.removeAt(i);
    price.removeAt(i);
    loaded.removeAt(i);

    //Updates the screen
    buildAllStockCards();
    setUpCards();

    //Save data without deleted stock.
    saveData();
  }

  saveData() async {
    //Setup shared preferences
    final SharedPreferences prefs = await _prefs;
    prefs.setStringList('stocks', stocks);

    //Coverts double array to string array
    List<String> amountsStr = [];
    for (int i = 0; i < amounts.length; i++) {
      amountsStr.add(amounts[i].toString());
    }
    //Saves the array amounts.
    prefs.setStringList('amounts', amountsStr);
  }

  loadData() async {
    //Setup empty arrays
    stocks = [];
    amounts = [];

    //Setup shared preferences
    final SharedPreferences prefs = await _prefs;

    //Loads stocks
    try {
      stocks = prefs.getStringList('stocks')!;
    } catch (e) {}

    //Loads amounts
    List<String> amountsStr = [];
    try {
      amountsStr = prefs.getStringList('amounts')!;
      for (int i = 0; i < amountsStr.length; i++) {
        amounts.add(double.parse(amountsStr[i]));
      }
    } catch (e) {}
  }

  setup() async {
    //Loads data from shared preferences
    await loadData();
    print("Data Loaded");

    //Loads data from api
    await getAllData();

    //Builds and setups cards
    buildAllStockCards();
    setUpCards();
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      // Sets the preferred orientation to portrait.
      DeviceOrientation
          .portraitUp, // Prevents the phone from going into landscape orientation.
    ]);
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;

    if (first) {
      setup();
      buildAllStockCards();
      setState(() {
        setUpCards();
      });

      first = false;
    }

    return Scaffold(
      backgroundColor: black,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            right: 0,
            child: SingleChildScrollView(
              child: Column(
                children: cards,
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            left: width / 2 - 50 + 25 / 2,
            child: Container(
              height: 75,
              width: 75,
              decoration: BoxDecoration(
                  color: darkBrightGreen,
                  border: Border.all(
                    //color: brightGreen,
                    width: 5,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(50),
                    topRight: Radius.circular(50),
                    bottomLeft: Radius.circular(50),
                    bottomRight: Radius.circular(50),
                  )),
              child: IconButton(
                icon: Icon(
                  CupertinoIcons.plus,
                  size: 50,
                  color: white,
                ),
                onPressed: () {
                  setState(() {
                    Alert(
                      context: context,
                      title: "Add Dividend Stock",
                      desc: "Enter the symbol of your stock below.",
                      style: AlertStyle(
                        backgroundColor: black,
                        descStyle: GoogleFonts.lato(
                          color: white,
                          fontSize: 25,
                        ),
                        titleStyle: GoogleFonts.lato(
                          color: white,
                          fontSize: 35,
                        ),
                        alertBorder: Border.all(
                          color: darkBrightGreen,
                          width: 5,
                        ),
                      ),
                      content: Column(
                        children: [
                          TextField(
                            style: GoogleFonts.lato(
                              color: white,
                              fontSize: 25,
                            ),
                            decoration: InputDecoration(
                              labelText: "Symbol",
                              labelStyle: TextStyle(color: brightGreen),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: darkBrightGreen),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: darkBrightGreen),
                              ),
                              border: UnderlineInputBorder(
                                borderSide: BorderSide(color: darkBrightGreen),
                              ),
                            ),
                            controller: symbolController,
                          ),
                          TextField(
                            style: GoogleFonts.lato(
                              color: white,
                              fontSize: 25,
                            ),
                            decoration: InputDecoration(
                              labelText: "Amount Of Shares",
                              labelStyle: TextStyle(color: brightGreen),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: darkBrightGreen),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: darkBrightGreen),
                              ),
                              border: UnderlineInputBorder(
                                borderSide: BorderSide(color: darkBrightGreen),
                              ),
                            ),
                            controller: amountController,
                          ),
                        ],
                      ),
                      buttons: [
                        DialogButton(
                          color: darkBrightGreen,
                          child: Text(
                            "Add",
                            style: TextStyle(color: Colors.white, fontSize: 20),
                          ),
                          onPressed: () {
                            if (amountController.text != "" &&
                                symbolController.text != "") {
                              amounts.add(double.parse(amountController.text));
                              stocks.add(symbolController.text);
                              addCard();
                            }

                            amountController.text = "";
                            symbolController.text = "";

                            Navigator.pop(context);
                          },
                          radius: BorderRadius.circular(0.0),
                        ),
                      ],
                    ).show();
                  });
                },
              ),
            ),
          )
        ],
      ),
    );
  }
}
