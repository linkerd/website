setTimeout(function(){    
    var buttonWrapper = document.querySelector('.button__wrapper');
    widthOriginal = buttonWrapper.getBoundingClientRect().width;
    console.log("-"+widthOriginal);

    if(widthOriginal>99){
        buttonWrapper.style.display = 'none'; 
    }
}, 2300);