# SwimplyCache

## What is this?
**SwimplyCache** is a simple, threadsafe caching solution. It is internally backed by a LinkedHashMap and very fast compared to NSCache.

 **SwimplyCache** will automatically empty itself in the event of a memory warning or a app background event.

## Usage

#### Create the Cache
```
 let cache = SwimplyCache<String, String>()
```

#### Add Value
``` 
cache.setValue("Value", forKey: "Key")
cache.setValue("Value", forKey: "Key", costs: 200)
```

#### Retrieve Value
```
let value = cache.value(forKey: "Key")
```

#### Remove Value

Swimply allows you to remove values by following operations.

```
cache.remove(.key(key: "Key"))
cache.remove(.all)
cache.remove(.byLimit(countLimit: 200))
cache.remove(.byCost(costLimit: 200))
```
