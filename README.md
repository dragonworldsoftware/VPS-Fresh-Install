# VPS-Fresh-Install
A PowerShell Batch Loader. Downloads and Installs either MT5 Forex.com or Trading.com

## Install Procedure
1. Download and Unzip the `Forex-Fresh-Install.zip`
2. Extract the program
3. In the Extracted folder: Find the `config.yaml` and open with `Windows Notepad`
4. In the `config.yaml` file you will see two sections. One for Forex.com and Trading.com
5. Locate your Broker.
6. Then add the `Login` and `Password` for you selected broker between the double quotes ""
7. DO NOT change the server information. 

```yaml
# config.yaml
forex_com_login=""
forex_com_password=""
forex_com_server="Forex.com-Live 536"

trading_com_login=""
trading_com_password=""
trading_com_server="Trading.comMarkets-MT5"
```

8. Save your changes to the file
9. Back in the Forex-Fresh-Install folder, locate the `Run-Installer` file and double-click it
10. You will get a pop-up asking if you want to run this. Select: `yes`
11. This will then show you a new PowerShell window.
```bash
Welcome to the MetaTrader5 Installer
======================================

Select Broker:
1. Forex.com MT5
2. Trading.com MT5
0. Exit

Enter your choice:
```

12. Type either `1` or `2`. Typing `0` will close the program. 
> If you expect it to auto log you in on setup. The `config.yaml` must have the correct credentials.

13. Press `Enter` on your keyboard to confirm your selection
14. Then remove you hands from the keyboard and watch MetaTrader Install and Auto Login the user.
15. If the program ran successfully. Installed and Logged in. You will get a chime notification sound. 

  
