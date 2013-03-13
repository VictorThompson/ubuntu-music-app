//script.js
var myArray = new Array()

function getList() {
    return myArray
}

function addItem(item) {
    myArray.push(item)
}

function contains(item) {
    return myArray.indexOf(item) !== -1
}

function clear() {
    myArray = []
}
