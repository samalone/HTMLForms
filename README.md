# HTMLForms
Construct HTML forms from encodable Swift objects — designed for Vapor

This library assists with creating HTML forms from encodable Swift structs and classes.
It's intended for use with Vapor, because it names its form inputs such that Vapor can
parse the resulting form submission back into the same Swift object. The library does
not actually depend on Vapor, so it could also be used in other projects.

The main class is HTMLFormEncoder. To encode an object, call `HTMLFormEncoder.encode(obj)`.

The output is not text, but a [scinfu/SwiftSoup](https://github.com/scinfu/SwiftSoup)
form Element. This provides a structured DOM tree that can be further customized 
before it is output. It can be converted to text by simply calling its .outerHtml() method.

## Example

```
struct SubscriptionRequest: Codable {
    var name: String;
    var email: String;
}

let request = SubscriptionRequest(name: "Llama", email: "llama@example.com")
print(HTMLFormEncoder.encode(request).outerHtml())
```

#### Output:

```
<form method="post" accept-charset="UTF-8">
 <div class="form-item">
  <label for="edit-name">Name</label>
  <input name="name" type="text" value="Llama" placeholder="name" id="edit-name">
 </div>
 <div class="form-item">
  <label for="edit-email">Email</label>
  <input name="email" type="text" value="llama@example.com" placeholder="email" id="edit-email">
 </div>
</form>
```
