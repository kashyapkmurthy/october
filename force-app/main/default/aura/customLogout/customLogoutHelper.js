({
  executeAction: function (action) {
    return new Promise(function (resolve, reject) {
      action.setCallback(this, function (response) {
        let state = response.getState();
        if (state === "SUCCESS") {
          let retVal = response.getReturnValue();
          resolve(retVal);
        } else if (state === "ERROR") {
          var errors = response.getError();
          if (errors) {
            if (errors[0] && errors[0].message) {
              reject(Error("Error message: " + errors[0].message));
            }
          } else {
            reject(Error("Unknown error"));
          }
        }
      });
      $A.enqueueAction(action);
    });
  },
  showToast: function (message, type) {
    var myToast = $A.get("e.force:showToast");
    myToast.setParams({
      message: message,
      type: type,
      mode: "dismissible"
    });
    myToast.fire();
  },
  handleError: function (error) {
    let errorMessage;
    if (error && error.body && error.body.message) {
      errorMessage = error.body.message;
    } else if (error && error.message) {
      errorMessage = error.message;
    } else if (error) {
      errorMessage = error;
    }
    return errorMessage;
  }
});