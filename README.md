# Top 10 Places App

An iOS Application that's provide you the top 10 places in your location. All of the places are sorted by distance within your current location.


## Appendix

This project is written on:
- Swift
- Pure SwiftUI
- Xcode 14.3
## Installation

In order to run this you need to have:
- Preferrably Xcode 14.3 but you can try to use Xcode 14.xx.
    - This is to avoid issues when running this project on lower versions of xcode and macOS.
- macOS Ventura since this is the version where the Xcode 14 series will run.
- __(Optional)__ Sourcetree for easier cloning but you can clone this using Git terminal.

After cloning the project, make sure that you select __main__ as the main branch.
After selecting the branch, you can open the project by:
- Opening xcode 14.3
- Selecting "Open a project or file"
- Browse using the path that you save during cloning
- Find the __.Top10Places.xcodeproj__ file then open it
Then in order to run the project you can simply press __ctrl + R__ on your keyboard to build and run.

No need to do additional libraries installation since this project isn't dependent on any 3rd party libraries or package dependency such as Swift Package manager or Cocoapods.
    
## Features

- __[Top-left]__ Status view to show the current status of retrieving/processing the top 10 places.
- __[Top-left]__ List button to show the top 10 places in your location
- __[Bottom-right]__ Current Location Button to go to your current location
- __[Bottom-right]__ Refresh Button to update the top 10 places within your current location
- __Pin Annotations__ on the map that shows the current rank based on the distance between the place and your location.
    - Upon tapping, it will show a callout that shows the place information.
        - The current rank of the place
        - The name of the place
        - The full address of the place
        - The distance between the selected place and your location in terms of meters.
        - The latitude and longtitude of the place
- __Info Annotation__ on the map that shows the number of places that have the same coordinates. All of the annotations that have the same coordinates are combined into one annotation.
    - Upon tapping, it will show the list of places that have the same coordinates.
        - Selecting the place on the list will show the callout.
- Pre-fetching/pre-cache of top 10 places
- Light/dark mode


## Screenshots (IPhone - Portrait)

![App Screenshot](https://i.ibb.co/DtVsrHt/main-iphone.png)
![App Screenshot](https://i.ibb.co/yWHdqdf/callout-iphone.png)
![App Screenshot](https://i.ibb.co/gSfpGgq/list-iphone.png)
![App Screenshot](https://i.ibb.co/mqbW9gL/listsame-iphone.png)

## Screenshots (IPhone - landscape)

![App Screenshot](https://i.ibb.co/tCSPqHZ/main-landscape-iphone.png)
![App Screenshot](https://i.ibb.co/gFGvTpG/callout-landscape-iphone.png)
![App Screenshot](https://i.ibb.co/H2Pdq4T/list-landscape-iphone.png)

## Screenshots (IPad - Portrait)

![App Screenshot](https://i.ibb.co/k579Yz7/main-ipad.png)
![App Screenshot](https://i.ibb.co/5GgfHVv/callout-ipad.png)
![App Screenshot](https://i.ibb.co/j54LJPf/list-ipad.png)
![App Screenshot](https://i.ibb.co/x1jqN72/listsame-ipad.png)

## Screenshots (IPad - landscape)

![App Screenshot](https://i.ibb.co/jvGKjPn/main-landscape-ipad.png)
![App Screenshot](https://i.ibb.co/B65SLp2/callout-landscape-ipad.png)
![App Screenshot](https://i.ibb.co/q7fmYpM/list-landscape-ipad.png)
![App Screenshot](https://i.ibb.co/f4yw0SQ/listsame-landscape-ipad.png)
