Map<String, Object> metadata = ...;

if (metadata.containsKey("documentType")) {
    Object value = metadata.get("documentType");
    // You can cast it if needed, e.g.:
    String documentType = (String) value;
    System.out.println("Document type: " + documentType);
} else {
    System.out.println("Key not found!");
}
