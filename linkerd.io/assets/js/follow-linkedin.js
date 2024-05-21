setTimeout(function(){    
    var buttonWrapper = document.querySelector('.linkedin__btn');
    widthOriginal = buttonWrapper.getBoundingClientRect().width;
    //console.log("-"+widthOriginal);

    if(widthOriginal>99){
        buttonWrapper.style.display = 'none'; 
    }
}, 2300);
