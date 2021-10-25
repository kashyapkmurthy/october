@isTest
global with sharing class MockHttpResponseGenerator implements HttpCalloutMock {
  //optional
  public String method { get; set; }

  //optional
  public String contentType { get; set; }
  //defaults to application/json
  {
    contentType = 'application/json';
  }

  //optional
  public Integer statusCode { get; set; }
  //defaults to success
  {
    statusCode = 200;
  }

  public String status { get; set; }
  {
    status = 'OK';
  }

  public String response { get; set; }

  public Blob blobResponseBody { get; set; }

  public MockHttpResponseGenerator() {
  }

  public MockHttpResponseGenerator(
    String method,
    String contentType,
    String response,
    Integer statusCode,
    String status
  ) {
    this.method = method;
    this.contentType = contentType;
    this.response = response;
    this.statusCode = statusCode;
    this.status = status;
  }

  // Implement this interface method
  global HTTPResponse respond(HTTPRequest req) {
    // Create a fake response
    HttpResponse res = new HttpResponse();
    res.setHeader('Content-Type', contentType);
    if (blobResponseBody != null) {
      res.setBodyAsBlob(blobResponseBody);
    } else {
      res.setBody(response);
    }
    res.setStatusCode(statusCode);
    res.setStatus(status);
    return res;
  }

  // Factory Methods
  public static MockHttpResponseGenerator jsonPost200Ok(String response) {
    return new MockHttpResponseGenerator(
      'POST',
      'application/json',
      response,
      200,
      'OK'
    );
  }

  public static MockHttpResponseGenerator jsonPost400BadRequest(
    String response
  ) {
    return new MockHttpResponseGenerator(
      'POST',
      'application/json',
      response,
      400,
      'Bad Request'
    );
  }

  public static MockHttpResponseGenerator jsonDelete200Ok() {
    return new MockHttpResponseGenerator(
      'DELETE',
      'application/json',
      '',
      200,
      'OK'
    );
  }

  public static MockHttpResponseGenerator jsonDelete400Exception() {
    return new MockHttpResponseGenerator(
      'DELETE',
      'application/json',
      '',
      400,
      'Exception'
    );
  }
}