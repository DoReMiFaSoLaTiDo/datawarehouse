// # Place all the behaviors and hooks related to the matching controller here.
// # All this logic will automatically be available in application.js.
// # You can use CoffeeScript in this file: http://coffeescript.org/
//
//

$(function(){
    $(".dim_selection").on('change',(function () {

        var myID = this.id;
        var id_to_change = '#' + 'biz_measures_'+ myID.slice(-1);
        var from_id = '#'+myID + ' option:selected'

        var data = $(from_id).val();
        console.log(id_to_change);
        $('.active').removeClass('active');
        $(id_to_change).addClass('active');

        $.ajax({
            url: "update_measures",
            type: "GET",
            datatype: 'script',
            data: {
                d_value: $(from_id).val()
            },
            success: function (data, status, xhr) {
                // console.log(data);
                change_select(data, id_to_change);
            },
            error: function (xhr, status, error) {
                console.log(xhr)
            }
        });

    }));
})

function change_select(data, id_to_change) {
    var json = jQuery.parseJSON(data);
    var options = [];
    json.each(function (key, index) {
        options.push({text: index, value:key});
    });
    $(id_to_change).replaceOptions(options);
}

