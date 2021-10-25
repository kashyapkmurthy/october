public class PaymentErrorResponse {

	public Payload payload;

	public class Payload {
		public Boolean success;
		public String apiName;
		public String version;
		public String correlationId;
		public String timestamp;
		public ErrorDetails errorDetails;
	}

	public class ErrorDetails {
		public Integer code;
		public String message;
		public String additionalInfo;
	}

	
	public static PaymentErrorResponse parse(String json) {
		return (PaymentErrorResponse) System.JSON.deserialize(json, PaymentErrorResponse.class);
	}
}