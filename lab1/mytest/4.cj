main() {
 var x : Int64 = 5
 let y : String
 let z = false
 if (x >= 5) {
    //9223372036854775807
   x = 9223372036854775805 + 6
 } else {
   y = "small"
 }
}