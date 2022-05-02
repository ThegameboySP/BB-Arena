local function stepPresentation(world, components, params)
    PresentationGroup:Step(world, components, params)
end

return {
    system = stepPresentation;
}