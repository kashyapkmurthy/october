({
  doInit: function (component, event, helper) {
    const logoutSNSWUserAction = component.get("c.logoutSNSWUser");

    helper
      .executeAction(logoutSNSWUserAction)
      .then(
        $A.getCallback((results) => {
          $A.get("e.force:logout").fire();
        })
      )
      .catch(
        $A.getCallback((error) => {
          const errorMessage = helper.handleError(error);
          helper.showToast(errorMessage, 'error');
        })
      );
  }
});