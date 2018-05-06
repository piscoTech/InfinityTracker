# InfinityTracker
Track your progress while running or walking in a simple way. Open the app and hit start to:
- Track your location and route in realtime on a map
- Accurately calculate calories using your latest weight entry from the Health app
- See details about distance, time, calories burned and current pace

Once you're finished your workout is automatically saved inside the Health app to access it even from other places. You can also see details of all your past workouts recorded inside the app and have a global statistics of total distance ran or walked and calories burned.

*Coming Soon on the AppStore*

## Screenshots

<inline><img src="https://user-images.githubusercontent.com/29719383/29948743-9ba7c3fe-8eeb-11e7-9cc1-8da94cb87697.png" width="165">
<img src="https://user-images.githubusercontent.com/29719383/29948749-9bf38f50-8eeb-11e7-8916-fcf98b320e29.png" width="165"><img src="https://user-images.githubusercontent.com/29719383/29948746-9bed5ed2-8eeb-11e7-925b-b3d67a11acd6.png" width="165"><img src="https://user-images.githubusercontent.com/29719383/29948745-9bec6374-8eeb-11e7-9fe7-40e46887601a.png" width="165"><img src="https://user-images.githubusercontent.com/29719383/29948744-9bea638a-8eeb-11e7-9d99-2dad937f1736.png" width="165">
<inline>

## Project Setup
The framework `MBLibrary` referenced by this project is available [here](https://github.com/piscoTech/MBLibrary), version currently in use is [1.2.2](https://github.com/piscoTech/MBLibrary/releases/tag/v1.2.2(9)).

## Customization
General behaviour of the app can be configured via properties of `HealthKitManager` class:

* `authRequired`, `healthReadData` and `healthWriteData`: Used to save the latest authorization requested in `UserDefaults`, when `authRequired` is greater than the saved value the user will be promped for authorization upon next launch, increment this value when adding new data to be read or write to `healthReadData` or `healthWriteData`.

The algorithm that takes care of tracking workout route, distance, calories burned and pace can be tweaked via the properties `dropThreshold`, `moveCloserThreshold`, `thresholdSpeed`, `accuracyInfluence`, `routeTimeAccuracy`, `detailsTimePrecision` and `paceTimePrecision` of `RunBuilder` class. For additional details refer to in-code documentation.

## Acknowledgements
Original work and core logic of the app by [Alexandre Linares](https://github.com/alekszilla/InfinityTracker).
