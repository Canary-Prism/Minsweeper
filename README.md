# Minsweeper
it's like minesweeper, but worse  
also it's in Swift

I'm assuming you know how to use Swift Package Manager. If not then here:

### how u use

```swift
let package = Package(
    name: "ProjectNameHere",
    dependencies: [
        .package(url: "https://github.com/Canary-Prism/Minsweeper", .branch("main")),
    ]
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "YourTarget",
            dependencies: [
                .product(name: "MinsweeperGame", package: "Minsweeper")
            ]
        ),
    ]
)


```