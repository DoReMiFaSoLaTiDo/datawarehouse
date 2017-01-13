// # Place all the behaviors and hooks related to the matching controller here.
// # All this logic will automatically be available in application.js.
// # You can use CoffeeScript in this file: http://coffeescript.org/
//
//
// $ ->
//   $(document).on 'change', '#biz_dimension_1', (evt) ->
//     $.ajax 'update_measures',
//       type: 'GET'
//       dataType: 'script'
//       data: {
//         d_value: $("#biz_dimension_1 option:selected").val()
//       }
//       error: (jqXHR, textStatus, errorThrown) ->
//         console.log("AJAX Error: #{textStatus}")
//       success: (data, textStatus, jqXHR) ->
//         console.log("Dynamic Measure select OK!")

$(function(){
    $("#biz_dimension_1").change(function() {

        var data = $("#biz_dimension_1 option:selected").val();

        $.ajax({
            url: "update_measures",
            type: "GET",
            datatype: 'script',
            data: {
                d_value: $("#biz_dimension_1 option:selected").val()
            },
            success: function (data, status, xhr) {
                console.log(data);
            },
            error: function (xhr, status, error) {
                console.log(xhr)
            }
        });
            // var key = $dropdown.val();
            // var vals = [];
            //
            //
            //
            // var $secondChoice = $("#second-choice");
            // $secondChoice.empty();
            // $.each(vals, function(index, value) {
            //     $secondChoice.append("<option>" + value + "</option>");
            // });


    });
})



// #// $(function(){
// #//     var data = {
// #//         d_value: jQuery('#biz_dimension_1 :selected').val()
// #//     }
// #//     jQuery.ajax({
// #//         url: 'update_measures',
// #//         type: 'GET',
// #//         dataType: 'script',
// #//         data: data
// #//     });
// #// }
// #
// #
// #// $(function(){
// #//   $("#biz_dimension_1").change(function(){
// #//     $.ajax({
// #//   url: "/update_measures",
// #//   type: "GET",
// #//   data: {
// #//     d_value: $(this).val();
// #//   }
// #// })
// #// });
// #// });