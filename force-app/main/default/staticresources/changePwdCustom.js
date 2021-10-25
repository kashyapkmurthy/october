function validatePwd() {
    let pwdElement = document.getElementById('changePassword1:chgForm:newpassword');
    let inputValue = pwdElement.value;
    let buttonElement = document.getElementById('changePassword1:chgForm:password-button');
    let result = true;
    let confrmPwdElement = document.getElementById('changePassword1:chgForm:confirmpassword');
    if(/[0-9]/.test(inputValue)){
        document.getElementById('numbers').classList.add("grn-color");
    }
    else{
        document.getElementById('numbers').classList.remove("grn-color");
        result = false;
    }
    if(/[A-Z]/.test(inputValue)){
        document.getElementById('upper').classList.add("grn-color");
    }
    else{
        document.getElementById('upper').classList.remove("grn-color");
        result = false;
    }                                     
    if(/[a-z]/.test(inputValue)){
        document.getElementById('lower').classList.add("grn-color");
    }
    else{
        document.getElementById('lower').classList.remove("grn-color");
        result = false;
    }                                     
    if(inputValue.length >= 8){
        document.getElementById('charcount').classList.add("grn-color");
    }
    else{
        document.getElementById('charcount').classList.remove("grn-color");
        result = false;
    }                                     
    if(/[-._!"`'#%&,:;<>=@{}~\$\(\)\*\+\/\\\?\[\]\^\|]/.test(inputValue)){
        document.getElementById('special').classList.add("grn-color");
    }
    else{
        document.getElementById('special').classList.remove("grn-color");
        result = false;
    }
    if(result == true)
    	result = confirmPwd(confrmPwdElement);
    else{
        if(!buttonElement.classList.contains("inpt-button-disabled")){
            buttonElement.classList.remove("inpt-button-enabled");
            buttonElement.classList.add("inpt-button-disabled");
        }
    }
    
    return result;
}

function confirmPwd(data){
    let pwdElement = document.getElementById('changePassword1:chgForm:newpassword');
    let pwdValue = document.getElementById('changePassword1:chgForm:newpassword').value;
    let buttonElement = document.getElementById('changePassword1:chgForm:password-button');
    let pwdMessElement = document.getElementById('confirmpassword-message');
    if(data.value.length >= 8 && data.value.length >= pwdValue.length && pwdValue == data.value &&
      !pwdElement.classList.contains("disabled")){
    	buttonElement.classList.remove("inpt-button-disabled", "btnDisabled");
        buttonElement.classList.add("inpt-button-enabled");
        pwdMessElement.classList.add("no-message");  
        pwdMessElement.classList.remove("password-message", "red-color");
        console.log('All good');
        return true;
    }
    else if(data.value.length >= pwdValue.length && pwdValue != data.value){
        pwdMessElement.classList.remove("no-message");                                        
        pwdMessElement.classList.add("password-message","red-color");
    	buttonElement.classList.remove("inpt-button-enabled");
        buttonElement.classList.add("inpt-button-disabled");
        return false;
    }else {
    	buttonElement.classList.remove("inpt-button-enabled");
        buttonElement.classList.add("inpt-button-disabled");
        pwdMessElement.classList.add("no-message");  
        pwdMessElement.classList.remove("password-message", "red-color");
        return false;
    }
}

function invokeActionFunction(){
    let boolvar = validatePwd();
    return boolvar;
}

function invokeChkboxFunction(){
    let pwdElement = document.getElementById('changePassword1:chgForm:newpassword');
    let confrmPwdElement = document.getElementById('changePassword1:chgForm:confirmpassword');
    let buttonElement = document.getElementById('changePassword1:chgForm:password-button');
    console.log('pwdElement...'+pwdElement.classList.contains("disabled"));

    if(pwdElement.classList.contains("disabled")){
    	pwdElement.classList.remove("disabled"); 
        confrmPwdElement.classList.remove("disabled"); 
        if(buttonElement.classList.contains("inpt-button-disabled")){
            if(confrmPwdElement.value.length >= 8 && confrmPwdElement.value.length >= pwdElement.value.length && pwdElement.value == confrmPwdElement.value){
                buttonElement.classList.remove("inpt-button-disabled", "btnDisabled");
                buttonElement.classList.add("inpt-button-enabled");
            }
        }
    }else {
        pwdElement.classList.add("disabled"); 
        confrmPwdElement.classList.add("disabled");
        if(!buttonElement.classList.contains("inpt-button-disabled")){
            buttonElement.classList.remove("inpt-button-enabled");
            buttonElement.classList.add("inpt-button-disabled", "btnDisabled");
        }
    }
    return;
}

window.onload=function()       
{        
    let buttonElement = document.getElementById('changePassword1:chgForm:password-button');
    buttonElement.classList.remove("btn");
    let pwdElement = document.getElementById('changePassword1:chgForm:newpassword');
    let confrmPwdElement = document.getElementById('changePassword1:chgForm:confirmpassword');
    let renderDeclaration = document.getElementById('changePassword1:declForm:theHiddenInput').value;
    if(renderDeclaration == 'false'){
    	pwdElement.classList.remove("disabled"); 
        confrmPwdElement.classList.remove("disabled"); 
    }
};