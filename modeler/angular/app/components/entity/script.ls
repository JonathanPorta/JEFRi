controller = !($scope, Model)->
	$scope.addField = !->
		$scope.entity.properties Model.runtime.build \Property, { name: "New Property", type: \string }
	$scope.addRelationship = !->
		relationship = Model.runtime.build \Relationship,
			name: "relationship"
			type: \has_a
			from_property: $scope.entity._definition!key
		relationship.from $scope.entity
		$scope.entity.relationships relationship

	$scope.delete = !->
		$scope.entity._destroy!

angular.module \modeler
	.controller \Entity, [\$scope, \Model, controller]


directive = ($, jsp) ->
	restrict: \E
	template: $.template \.entity
	replace: true
	controller: \Entity
	link: !(scope, element) ->
		element
			.draggable do
				start: jsp.drag.start
				drag: jsp.drag.drag
				stop: jsp.drag.stop
			.resizable handles: \e

angular.module \modeler
	.directive \entity, [\jQuery, \JSPlumb, directive]
