Automox Worklet: Test Website  
Every find yourself in need of testing a site remotely? Wondering if it
is actually up? Want to test it from the eyes of your users? This tool is 
for you!  

Can stand alone or as worklet!  

Examples:  

.\Test-Website.ps1   

--> returns test against automox console by default.
{  
    "loadedInSeconds":  0.175,  
    "statusDescription":  "OK",  
    "siteTested":  "https://console.automox.com/",  
    "serverType":  "nginx",  
    "statusCode":  200  
}  

.\Test-Website.ps1 -target www.google.com   

--> Tests a specific target you define. This works from your ps console  
but most likely will not work for worklets.  
{
    "loadedInSeconds":  0.1323,  
    "statusDescription":  "OK",  
    "siteTested":  "www.google.com",  
    "serverType":  "gws",  
    "statusCode":  200  
}  

.\Test-Website.psl -verbose  
Shows the hidden outputs for testing.  
VERBOSE: Test-Website.ps1 Initial Setup, Started running on 10/02/2020 15:29:49  
VERBOSE: GET http://www.google.com/ with 0-byte payload  
VERBOSE: received -1-byte response of content type text/html; charset=UTF-8  
{
    "loadedInSeconds":  0.0772,  
    "statusDescription":  "OK",  
    "siteTested":  "www.google.com",  
    "serverType":  "gws",  
    "statusCode":  200  
}
VERBOSE: Executed in: 0 seconds  


Faq:  

Q: Can I change the default site to something I want to test against?  
A: Yes! In the Param section, change $target to whatever you like. 

Q: Why JSON as a return?  
A: I find it's easier to accept that input into something else like  
another powershell script or a different API or loggin agent like datadog.  